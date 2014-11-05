package = "resty-entity"
version = "scm-1"
source = {
    url = "git://github.com/mah0x211/lua-resty-entity.git"
}
description = {
    summary = "request entity handling module for openresty",
    homepage = "https://github.com/mah0x211/lua-resty-entity", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "util >= 1.0",
    "halo >= 1.0",
    "httpconsts >= 1.0"
}
build = {
    type = "builtin",
    modules = {
        ["resty.entity"] = "entity.lua",
        ["resty.entity.form"] = "lib/form.lua",
        ["resty.entity.multipart"] = "lib/multipart.lua",
        ["resty.entity.json"] = "lib/json.lua"
    }
}

