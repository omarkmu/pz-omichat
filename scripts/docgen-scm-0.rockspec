rockspec_format = "3.0"
package = "docgen"
version = "scm-0"

dependencies = {
    "lua >= 5.2",
    "fluent >= 0.2.0",
    "lua_cliargs >= 3.0.2",
    "lpath >= 0.4.0",
}

source = {
    url = "git://github.com/omarkmu/pz-omichat.git"
}

build = {
    modules = {
        docgen = "docgen.lua",
    },
    install = {
        bin = {
            docgen = "docgen.lua",
        }
    }
}
