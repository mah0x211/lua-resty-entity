package = "resty-entity"
version = "1.3.3-1"
source = {
    url = "git://github.com/mah0x211/lua-resty-entity.git",
    tag = "v1.3.3"
}
description = {
    summary = "request entity handling module for openresty",
    homepage = "https://github.com/mah0x211/lua-resty-entity", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "lua-resty-upload >= 0.09",
    "lua-cjson >= 2.1.0",
    "halo >= 1.1.8",
    "httpconsts >= 1.0.1",
    "util >= 1.3.3"
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

