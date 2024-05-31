"""
Performs validation on translation files.
"""

import argparse
from pathlib import Path
from enum import IntEnum

default_encodings = {
    'EN': 'utf_8',
    'AR': 'cp1252',
    'CA': 'iso8859_15',
    'CH': 'utf_8',
    'CN': 'utf_8',
    'CS': 'cp1250',
    'DA': 'cp1252',
    'DE': 'cp1252',
    'EE': 'cp1252',
    'ES': 'cp1252',
    'FI': 'cp1252',
    'FR': 'cp1252',
    'HU': 'cp1250',
    'ID': 'utf_8',
    'IT': 'cp1252',
    'JP': 'utf_8',
    'KO': 'utf_16',
    'NL': 'cp1252',
    'NO': 'cp1252',
    'PH': 'utf_8',
    'PL': 'cp1250',
    'PT': 'cp1252',
    'PTBR': 'cp1252',
    'RO': 'utf_8',
    'RU': 'cp1251',
    'TH': 'utf_8',
    'TR': 'cp1254',
    'UA': 'utf_8',
}

warn_strings = {
    'identical': '{0} is identical to base locale',
    'duplicate': 'duplicate string {0}',
    'extra': 'string {0} is not present in the base locale',
    'extra_file': '{0} file is missing in the base locale',
    'missing': 'string {0} is missing',
    'missing_file': '{0} file is missing',
    'substitution_count': 'wrong number of substitutions in {0}',
}


class Verbosity(IntEnum):
    SILENT = 0
    MACHINE_READABLE = 1
    HUMAN_READABLE = 2


def verbosity_arg(arg):
    try:
        value = int(arg)
    except ValueError:
        raise argparse.ArgumentTypeError('must be an integer')

    if not (0 <= value <= 2):
        raise argparse.ArgumentTypeError('must be in [0, 2]')

    return Verbosity(value)


class TranslationCheckContext:
    def __init__(
        self, base_locale: str, global_ignore: str, encodings: str, verbosity: Verbosity
    ):
        self.base_locale = base_locale
        self.locale = base_locale
        self.encoding = 'utf_8'
        self.group = ''
        self.line = 0

        self.verbosity = verbosity
        self.encodings = self.read_encodings(encodings)
        self.global_ignore = self.read_ignore_set(global_ignore)
        self.line_ignore = set()
        self.seen = set()
        self.seen_groups = set()
        self.base_groups = set()
        self.strings: dict[str, dict[str, str]] = {}
        self.substitution_counts: dict[str, dict[str, int]] = {}
        self.warnings: list[tuple[str, str]] = []

    @property
    def is_base(self):
        return self.locale == self.base_locale

    @property
    def has_warnings(self):
        return len(self.warnings) > 0

    def reset(self):
        self.group = ''
        self.encoding = 'utf_8'
        self.line = 0
        self.locale = self.base_locale
        self.strings.clear()
        self.substitution_counts.clear()
        self.line_ignore.clear()
        self.seen.clear()
        self.seen_groups.clear()
        self.base_groups.clear()
        self.warnings.clear()

    def add_group(self, group: str):
        self.strings[group] = {}
        self.substitution_counts[group] = {}

    def add_string_info(self, group: str, key: str, value: str, substitutions: int):
        strings = self.strings.get(group)
        substs = self.substitution_counts.get(group)

        if strings is None:
            strings = {}
            self.strings[group] = strings

        if substs is None:
            substs = {}
            self.substitution_counts[group] = substs

        strings[key] = value
        substs[key] = substitutions

    def add_warning(self, code: str, keyOrGroup: str, group: str | None = None):
        if self.should_ignore(code):
            return

        if group is None:
            group = self.group

        if self.line == 0 or code.endswith('_file'):
            line = ''
        else:
            line = str(self.line)

        warn_string = warn_strings.get(code)
        if not warn_string:
            return

        if self.verbosity > Verbosity.MACHINE_READABLE:
            prefix = ''
            warn_string = warn_string.format(keyOrGroup)
        else:
            details = ','.join([self.locale, group, line, code])
            prefix = f'[{details}] '
            warn_string = keyOrGroup

        warn_string = f'{prefix}{warn_string}'
        if not warn_string:
            return

        self.warnings.append((warn_string, self.locale))

    def has_group(self, group: str):
        return self.strings.get(group) is not None

    def next_line(self):
        self.line += 1

    def start_subdir(self, locale: str):
        self.locale = locale
        self.seen_groups = set()

        if self.is_base:
            self.base_groups = self.seen_groups

        self.update_encoding()

    def start_file(self, group: str) -> dict[str, str] | None:
        self.line = 0
        self.group = group
        self.seen = set()
        self.seen_groups.add(group)
        if not self.has_group(group):
            if self.is_base:
                self.add_group(group)
            else:
                return None

        return self.strings[group]

    def update_ignore(self, line_ignore: str):
        self.line_ignore = self.read_ignore_set(line_ignore)

    def reset_ignore(self):
        self.line_ignore.clear()

    def should_ignore(self, err: str):
        return err in self.global_ignore or err in self.line_ignore

    def get_string_info(self, group: str, key: str) -> tuple[str | None, int | None]:
        strings = self.strings.get(group)
        substs = self.substitution_counts.get(group)
        if strings is None or substs is None:
            return (None, None)

        return (strings.get(key), substs.get(key, 0))

    def update_encoding(self):
        encoding = self.encodings.get(self.locale)
        if encoding:
            self.encoding = encoding
            return

        self.encoding = default_encodings.get(self.locale, 'utf_8')

    def read_ignore_set(self, line: str) -> set[str]:
        if not line:
            return set()

        ignore_start = line.find('---@ignore ', line.rfind('"') + 1)
        if ignore_start == -1:
            return set()

        return set(s.strip() for s in line[ignore_start + 11 :].split(','))

    def read_encodings(self, encodings: str) -> dict[str, str]:
        result = {}

        parts = encodings.split(',')
        for part in parts:
            pair = part.split(':')
            if len(pair) != 2:
                continue

            key = pair[0].strip()
            result[key] = pair[1].strip()

        return result


class TranslationChecker:
    def __init__(
        self,
        string_dir: Path,
        base_locale: str,
        ignore: str,
        encodings: str,
        verbosity: Verbosity,
    ):
        self.string_dir = string_dir
        self.base_subdir = string_dir / base_locale
        self.ctx = TranslationCheckContext(
            base_locale, f'---@ignore {ignore}', encodings, verbosity
        )

    def run(self, strict: bool):
        ctx = self.ctx
        ctx.reset()

        base = self.base_subdir
        if not base.exists():
            return self.fatal(f'base locale directory {base} does not exist')

        # check base locale
        self.check_subdir(base)

        # check other locales
        for f in self.string_dir.iterdir():
            if f.name == ctx.base_locale:
                continue

            self.check_subdir(f)

        if ctx.verbosity > Verbosity.SILENT:
            self.display_results()

        if strict and ctx.has_warnings:
            return False

        return True

    def display_results(self):
        ctx = self.ctx
        if not ctx.has_warnings:
            print('OK')
            return
        elif ctx.verbosity >= Verbosity.MACHINE_READABLE:
            print('Finished with warnings')

        seen_locales = set()
        for warning, locale in ctx.warnings:
            if locale not in seen_locales:
                seen_locales.add(locale)

                if ctx.verbosity >= Verbosity.HUMAN_READABLE:
                    print()
                    print(f'[{locale}]')

            print(warning)

    def check_subdir(self, dir: Path):
        if not dir.is_dir():
            return

        ctx = self.ctx
        ctx.start_subdir(dir.stem)
        for f in dir.iterdir():
            self.check_file(f)

        if ctx.is_base:
            return

        # check for not found files
        for group in ctx.base_groups:
            if group not in ctx.seen_groups:
                ctx.add_warning('missing_file', f'{group}_{ctx.locale}', group)

    def check_file(self, f: Path):
        ctx = self.ctx
        if not f.is_file() or f.suffix.lower() != '.txt':
            return

        parts = f.stem.split('_')
        if len(parts) < 2 or parts[-1] != ctx.locale:
            return

        base_strings = self.ctx.start_file(parts[0])
        if base_strings is None:
            ctx.add_warning('extra_file', f'{ctx.group}_{ctx.locale}', ctx.group)
            return  # nothing to compare against

        encoding = ctx.encoding
        content = f.read_text(encoding)

        cur_key = ''
        cur_value = ''
        should_continue = False

        # parse similarly to how the game does, including some quirks
        ctx.next_line()
        for line in content.splitlines()[1:]:
            ctx.next_line()
            line = line.strip()
            eq_pos = line.find('=')

            if line.find('"') != -1 and eq_pos != -1:
                cur_key = line[:eq_pos].strip()
                after_eq = line[eq_pos + 1 :]
                cur_value = after_eq[after_eq.find('"') + 1 : after_eq.rfind('"')]

                if line.find('..') != -1:
                    should_continue = True
            elif not line or line.find('--') != -1:
                should_continue = False
            else:
                should_continue = line.endswith('..')
                if should_continue:
                    cur_value += line[line.find('"') + 1 : line.rfind('"')]

            if should_continue:
                should_continue = self.allows_continue(cur_key)

            if not should_continue or not line.endswith('..'):
                self.ctx.update_ignore(line)
                self.check_string(cur_key, cur_value)
                self.ctx.reset_ignore()

                cur_key = ''
                cur_value = ''
                should_continue = False

        if self.ctx.is_base:
            return

        # check for not found strings
        for key in base_strings.keys():
            if key not in ctx.seen:
                ctx.add_warning('missing', key)

    def check_string(self, key: str, value: str):
        ctx = self.ctx
        if key in ctx.seen:
            ctx.add_warning('duplicate', key)
        elif key:
            ctx.seen.add(key)
            subst_count = self.count_substitutions(value)

            if ctx.is_base:
                ctx.add_string_info(ctx.group, key, value, subst_count)
            else:
                base_value, base_substs = ctx.get_string_info(ctx.group, key)

                if base_value is None:
                    ctx.add_warning('extra', key)
                elif base_value == value:
                    ctx.add_warning('identical', key)

                if base_substs is not None and subst_count != base_substs:
                    ctx.add_warning('substitution_count', key)

    def allows_continue(self, key: str) -> bool:
        if key.startswith('Recipe_'):
            return False
        if key.startswith('EvolvedRecipeName_'):
            return False
        if key.startswith('ItemName_'):
            return False
        if key.startswith('DisplayName'):
            return False

        return True

    def count_substitutions(self, string: str) -> int:
        return sum([1 if string.find('%' + str(i)) != -1 else 0 for i in range(1, 5)])

    def fatal(self, err: str):
        if self.ctx.verbosity > Verbosity.SILENT:
            print(f'[FATAL] {err}')

        return False


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='translation-check', description='Checks translation files.'
    )

    parser.add_argument('mod_path')
    parser.add_argument('-b', '--base', type=str, default='EN')
    parser.add_argument(
        '-v', '--verbosity', type=verbosity_arg, default=Verbosity.MACHINE_READABLE
    )
    parser.add_argument('-e', '--encodings', type=str, default='')
    parser.add_argument('--strict', action='store_true')
    parser.add_argument('--ignore', type=str, default='')
    parser.add_argument(
        '--string-subdir', type=str, default='media/lua/shared/Translate'
    )

    args = parser.parse_args()

    string_path = Path(args.mod_path) / args.string_subdir
    checker = TranslationChecker(
        string_path, args.base, args.ignore, args.encodings, args.verbosity
    )

    if not checker.run(args.strict):
        exit(1)
