"""
Produces type stubs from the output of lua-language-server documentation JSON files.
"""

import json
import argparse
import traceback
from re import match, search, sub


class LuaDocType:
    def __init__(self, name: str):
        self.name = name
        self.desc: str | None = None
    
    def set_desc(self, desc: str):
        self.desc = desc
    
    def try_set_desc(self, desc: str | None):
        if desc is None:
            return

        self.set_desc(desc)

class LuaAlias(LuaDocType):
    def __init__(self, name: str):
        super().__init__(name)
        self.elements: list[str] = []

    def add_element(self, view: str):
        self.elements.append(view)

class LuaArgument(LuaDocType):
    def __init__(
        self,
        name: str,
        type: str,
        desc: str | None = None,
        is_return: bool = False
    ):
        super().__init__(name or '')
        self.type = type
        self.desc = desc
        self.is_return = is_return

class LuaReturn(LuaDocType):
    def __init__(
        self,
        name: str | None,
        type: str,
        desc: str | None = None,
    ):
        super().__init__(name or '')
        self.type = type
        self.desc = desc

class LuaFunction(LuaDocType):
    def __init__(
        self,
        *,
        name: str,
        is_method: bool,
        args: list[LuaArgument],
        returns: list[LuaReturn],
        desc: str | None = None,
        visibility: str | None = None
    ):
        super().__init__(name)
        self.indexer = ':' if is_method else '.'
        self.args = args
        self.returns = returns
        self.desc = desc
        self.visibility = visibility

class LuaField(LuaDocType):
    def __init__(self, name: str, visibility: str | None):
        super().__init__(name)
        self.visibility = visibility
        self.types: set[str] = set()

    def add_type(self, view: str):
        self.types.add(view)

class LuaClass(LuaDocType):
    def __init__(self, name: str):
        super().__init__(name)
        self.desc: str | None = None
        self.base_classes: list[str] = []
        self.generics: str | None = None
        self.functions: list[LuaFunction] = []
        self.functionsByName: dict[str, LuaFunction] = {}
        self.fields: list[LuaField] = []
        self.fieldsByName: dict[str, LuaField] = {}

    def add_base_class(self, view: str):
        self.base_classes.append(view)

    def add_base_type_table(self, view: str):
        matchObj = search('<([^>]+)>', view)
        if matchObj:
            # this can only handle one non-nested generic definition
            self.generics = matchObj.group(1)

        # clean up generics in view
        self.add_base_class(view.replace('<', '').replace('>', ''))

    def add_field(self, field: LuaField):
        if self.fieldsByName.get(field.name):
            return False

        self.fields.append(field)
        self.fieldsByName[field.name] = field
        return True

    def add_function(self, func: LuaFunction):
        if self.functionsByName.get(func.name):
            return False

        self.functions.append(func)
        self.functionsByName[func.name] = func
        return True

    def get_field(self, name: str):
        return self.fieldsByName.get(name)

    def get_or_create_field(self, name: str, visibility: str | None = None):
        field = self.get_field(name)
        if not field:
            field = LuaField(name, visibility)

        if visibility:
            field.visibility = visibility
        
        return field

class LuaDocResult:
    def __init__(self):
        self.aliases: list[LuaAlias] = []
        self.classes: list[LuaClass] = []
        self.classesByName: dict[str, LuaClass] = {}

    def add_alias(self, alias: LuaAlias):
        self.aliases.append(alias)

    def add_class(self, cls: LuaClass):
        self.classes.append(cls)
        self.classesByName[cls.name] = cls
    
    def get_or_add_class(self, name: str):
        cls = self.classesByName.get(name)
        if cls:
            return cls

        cls = LuaClass(name)
        self.add_class(cls)
        return cls


class LuaDocReader:
    def __init__(
        self,
        *,
        name_pattern: str | None = None,
        file_pattern: str | None = None,
    ):
        self.name_pattern = name_pattern
        self.file_pattern = file_pattern
        self._classesByName: dict[str, LuaClass] = {}
        self._result = LuaDocResult()

    def read_file(self, path):
        with open(path, 'r') as file:
            content = json.loads(file.read())

        return self.read(content)

    def read(self, content):
        self._result = LuaDocResult()
        for element in content:
            if self.name_pattern and not match(self.name_pattern, element['name']):
                continue

            self._read_item(element)
        
        return self._result

    def _read_item(self, element):
        defines = element.get('defines', [])
        if len(defines) == 0:
            return

        is_class = False
        for dfn in defines:
            file = dfn.get('file')
            if file and self.file_pattern and not match(self.file_pattern, file):
                continue

            match dfn['type']:
                case 'doc.alias':
                    self._read_alias(element, dfn)
                case 'doc.class':
                    is_class = True
                    self._read_class_dfn(element, dfn)
                case 'doc.enum':
                    self._read_enum(element)

        if is_class:
            self._read_class_fields(element)

    def _read_alias(self, element, dfn):
        extends = dfn.get('extends', {})
        types = extends.get('types', [])

        alias = LuaAlias(element['name'])
        for aliased in types:
            alias.add_element(aliased['view'])

        self._result.add_alias(alias)

    def _read_class_dfn(self, element, dfn):
        cls = self._result.get_or_add_class(element['name'])

        for base in dfn.get('extends', []):
            match base['type']:
                case 'doc.extends.name':
                    cls.add_base_class(base['view'])
                case 'doc.type.table':
                    cls.add_base_type_table(base['view'])

        cls.try_set_desc(element.get('rawdesc'))

    def _read_class_fields(self, element):
        cls = self._result.get_or_add_class(element['name'])

        for obj in element['fields']:
            match obj['type']:
                case 'doc.field':
                    self._read_doc_field(obj, cls)
                case 'setfield':
                    self._read_set_field(obj, cls)
                case 'setmethod':
                    self._read_class_function(obj, cls, True)

    def _read_doc_field(self, obj, cls: LuaClass):
        field = cls.get_or_create_field(obj['name'], obj.get('visible'))
        extends = obj.get('extends', {})

        for fieldType in extends.get('types', []):
            field.add_type(fieldType['view'])

        field.try_set_desc(obj.get('rawdesc'))
        cls.add_field(field)

    def _read_set_field(self, obj, cls: LuaClass):
        extends = obj['extends']
        if extends['type'] == 'function':
            return self._read_class_function(obj, cls, False)

        field = cls.get_or_create_field(obj['name'], obj.get('visible'))
        field.add_type(extends['view'])
        field.try_set_desc(obj.get('rawdesc'))

        cls.add_field(field)
    
    def _read_class_function(self, obj, cls: LuaClass, is_method: bool):
        extends = obj['extends']

        args = []
        returns = []
        for argObj in extends['args']:
            if is_method and argObj['type'] == 'self':
                continue

            name = argObj.get('name', argObj['type'])
            args.append(LuaArgument(name, argObj['view'], argObj.get('rawdesc')))

        for retObj in extends.get('returns', []):
            returns.append(LuaReturn(
                retObj.get('name'),
                retObj['view'],
                retObj.get('rawdesc'),
            ))

        cls.add_function(LuaFunction(
            name=obj['name'],
            is_method=is_method,
            args=args,
            returns=returns,
            desc=obj.get('rawdesc'),
            visibility=obj.get('visible')
        ))

    def _read_enum(self, element):
        # not enough info, so read as unknown alias and tag as enum
        alias = LuaAlias(element['name'])
        alias.add_element('unknown')
        alias.set_desc('(enum)\n' + element.get('rawdesc', ''))

        self._result.add_alias(alias)

class LuaDocStubWriter:
    def __init__(self) -> None:
        self.out: list[str] = []

    def write_file( self, info: LuaDocResult, out_path: str):
        result = self.write_string(info)
        with open(out_path, 'w') as file:
            file.write(result)

    def write_string(self, info: LuaDocResult):
        self.out = [ '---@meta\n' ]

        for alias in info.aliases:
            self._write_alias(alias)

        for cls in info.classes:
            self._write_class(cls)

        return ''.join(self.out)

    def _append(self, text: str):
        self.out.append(text)
    
    def _clean_varargs(self, s):
        # very messy replacement to handle `...any`
        return sub(r'\.\.\.([^,)]+)([,)])', r'...: \1\2', s)
    
    def _get_field_type(self, field: LuaField):
        out = []
        for i, view in enumerate(sorted(field.types)):
            out.append(' | ' if i > 0 else ' ')
            out.append(self._clean_varargs(view))
        return ''.join(out)

    def _write_alias(self, alias: LuaAlias):
        if alias.desc:
            self._append('\n---')
            self._append(alias.desc.replace('\n', '\n---'))

        self._append('\n---@alias ')
        self._append(alias.name)

        for element in alias.elements:
            self._append('\n---| ')
            self._append(element)

        self._append('\n')
    
    def _write_class(self, cls: LuaClass):
        if cls.desc:
            self._append('\n---')
            self._append(cls.desc.replace('\n', '\n---'))

        self._append('\n---@class ')
        self._append(cls.name)

        if cls.generics:
            self._append('<')
            self._append(cls.generics)
            self._append('>')

        if cls.base_classes:
            self._append(' : ')

        for i, base in enumerate(cls.base_classes):
            if i > 0:
                self._append(', ')
            self._append(base)

        for field in cls.fields:
            self._write_field(field, cls)

        if cls.functions:
            table_name = cls.name.replace('.', '_')
            self._append('\nlocal ')
            self._append(table_name)
            self._append(' = {}')

            for func in cls.functions:
                self._write_function(func, table_name)
        
        self._append('\n')

    def _write_field(self, field: LuaField, cls: LuaClass):
        # ignore self-referential __index fields
        if field.name == '__index' and self._get_field_type(field).strip() == cls.name:
            return

        self._append('\n---@field ')

        if field.visibility and field.visibility != 'public':
            self._append(field.visibility)
            self._append(' ')

        self._append(field.name)
        self._append(self._get_field_type(field))

        if field.desc:
            self._append(' ')
            self._append(field.desc.replace('\n', ' '))

    def _write_function(self, func: LuaFunction, table_name: str):
        self._append('\n')
        if func.desc:
            for line in func.desc.split('\n'):
                # less-than-ideal way to get rid of the autogen content
                # but it works for our docs
                if line.startswith('```lua') or line.startswith('See:'):
                    break
                self._append('\n---')
                self._append(line)

        if func.visibility and func.visibility != 'public':
            self._append('\n---@')
            self._append(func.visibility)

        for arg in func.args:
            self._write_function_arg(arg)

        for ret in func.returns:
            self._write_function_return(ret)

        self._append('\nfunction ')
        self._append(table_name)
        self._append(func.indexer)
        self._append(func.name)
        self._append('(')

        for i, arg in enumerate(func.args):
            if i > 0:
                self._append(', ')
            self._append(arg.name)

        self._append(') end')
    
    def _write_function_arg(self, arg: LuaArgument):
        self._append('\n---@param ')
        self._append(arg.name)
        self._append(' ')

        self._append(self._clean_varargs(arg.type))

        if arg.desc:
            self._append(' ')
            self._append(arg.desc.replace('\n', ' '))
    
    def _write_function_return(self, ret: LuaReturn):
        self._append('\n---@return ')
        self._append(self._clean_varargs(ret.type))

        if ret.name != '':
            self._append(' ')
            self._append(ret.name)

        if ret.desc:
            self._append(' ')
            self._append('#' if ret.name == '' else '')
            self._append(ret.desc.replace('\n', ' '))


def run(*, in_path: str, out_path: str, name_pattern: str | None, file_pattern: str | None):
    reader = LuaDocReader(
        name_pattern=name_pattern,
        file_pattern=file_pattern,
    )
    writer = LuaDocStubWriter()

    writer.write_file(
        reader.read_file(in_path),
        out_path=out_path,
    )


if __name__ == '__main__':
    parser = argparse.ArgumentParser(prog='stubgen')
    parser.add_argument('path')
    parser.add_argument('-o', '--output', required=True)
    parser.add_argument('-n', '--name-pattern', dest='name_pattern')
    parser.add_argument('-f', '--file-pattern', dest='file_pattern')

    args = parser.parse_args()

    try:
        run(
            in_path=args.path,
            out_path=args.output,
            name_pattern=args.name_pattern,
            file_pattern=args.file_pattern,
        )
    except Exception:
        traceback.print_exc()
        exit(1)
