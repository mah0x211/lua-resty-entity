lua-resty-entity
=========

request entity handling module for openresty.

## Dependencies

- [cjson](https://github.com/mpx/lua-cjson): Lua CJSON is a fast JSON encoding/parsing module for Lua
- [httpconsts](https://github.com/mah0x211/lua-httpconsts): HTTP method names and status code constants module
- [resty-upload](https://github.com/openresty/lua-resty-upload): Streaming reader and parser for http file uploading based on ngx_lua cosocket
- [util](https://github.com/mah0x211/lua-util): useful utility functions module


## Installation

```
$ luarocks install resty-entity --from=http://mah0x211.github.io/rocks/
```

## Usage

```
daemon off;
worker_processes    1;

events {
    worker_connections  1024;
    accept_mutex_delay  100ms;
}


http {
    sendfile            on;
    tcp_nopush          on;
    #keepalive_timeout  0;
    keepalive_requests  500000;
    #gzip               on;
    open_file_cache     max=100;
    include             mime.types;
    default_type        text/html;
    index               index.html;
    resolver            8.8.8.8;
    resolver_timeout    5;

    #
    # log settings
    #
    access_log  off;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';


    #
    # lua global settings
    #
    lua_check_client_abort  on;
    lua_code_cache          on;

    server {
        listen      1080;
        root        html;

        #
        # content handler: html
        #
        location ~* \.(html|htm)$ {
            content_by_lua "
                local inspect = require('util').inspect;
                local Entity = require('resty.entity');
                local req = Entity.new();
                local res, status, err, _;

                if req.method == 'POST' then
                    _, status, err = req:getBody();
                end

                ngx.say( inspect({ req, status, err }) );
            ";
        }
    }
}
```

## Create an Request Entity

### req = Entity.new( [methodName1, [methodName2, [...]]] )

returns an new Request Entity.

- **Parameters**
    - `methodName:string`: method names that accepts the entity body. default: `POST` and `PUT`

- **Returns**
    - `req:table`: an request entity object that contains the following fields;
        - `method`: same as return value of `ngx.req.get_method()`
        - `scheme`: same as value of `ngx.var.scheme`
        - `uri`: same as value of `ngx.var.uri`
        - `request_uri`: same as value of `ngx.var.request_uri`
        - `query`: same as return value of `ngx.req.get_uri_args()`
        - `header`: same as return value of `ngx.req.get_headers()`


## Getting a Request Entity Body

### body, status, err = req:getBody( ... )

This method check the request content type, and calls the appropriate parser automatically.


- **Parameters**
    - `...`: arguments for the parser

- **Returns**
    - `body:table`: a request entity body
    - `status:number`: a http status code
        - `204:NO_CONTENT`: the request entity body is empty
        - `406:NOT_ACCEPTABLE`: the request method does not supported a entity body
        - `415:UNSUPPORTED_MEDIA_TYPE`: the request entity body content-type does not supported
        - `500:INTERNAL_SERVER_ERROR`: the parser returned an unknown status code (incorrect implementation)
        - `XXX`: status code that returned by the parser
    - `err:string`: an error string


currently, supports the following content types;

- `application/x-www-form-urlencoded`: this content type will be parsed with `resty.entity.form` module
- `multipart/form-data`: this content type will be parsed with `resty.entity.multipart` module
- `application/json`: this content type will be parsed with `resty.entity.json` module


### Form Parser

the form parser implements by `resty.entity.form` module.

#### body, status, err = resty.entity.form()

- **Returns**
    - `body:table`: a request entity body
    - `status:number`: a http status code
        - `204:NO_CONTENT`: the request entity body is empty
    - `err:string`: an error string


### JSON Parser

the json parser implements by `resty.entity.json` module.

#### body, status, err = resty.entity.json()

- **Returns**
    - `body:table`: a request entity body
    - `status:number`: a http status code
        - `204:NO_CONTENT`: the request entity body is empty
        - `422:UNPROCESSABLE_ENTITY`: the request entity body might be corrupted
    - `err:string`: an error string


### Multipart Parser

the multipart form-data parser implements by `resty.entity.multipart` module.

#### body, status, err = resty.entity.multipart( [cfg] )

- **Parameters**
    - `cfg:table`: you can change the following parser configuration by this argument;
        - `TMPDIR`: path of upload file directory (default: `'/tmp'`)
        - `PREFIX`: prefix of temporary filename (default: `'entity-'`)
        - `TIMEOUT`: read timeout (default: `1000`)
        - `BUFLEN`: read buffer-size (default: `4096`)
        - `MAXLEN`: maximum bytes of file-size (default: `1024*100`)
- **Returns**
    - `body:table`: a request entity body
    - `status:number`: a http status code
        - `400:BAD_REQUEST`: invalid request entity body format
        - `413:REQUEST_ENTITY_TOO_LARGE`: the request entity body size  exceeded the limitation of capacity
        - `500:INTERNAL_SERVER_ERROR`: the following cases are considered if this error is returned;
            - occurred by a system error
            - invalid arguments passed
    - `err:string`: an error string


## Add a Custom Parser

you can add custom parsers by `Entity.setBodyParser` API at the init phase of openresty.

### Entity.setBodyParser( def )

- **Parameters**
    - `def:table`: to add the content-type associated parser function
        - `key:string`: content-type
        - `val:function`: parser function

the parser function **must** be returned entity body, or status code.

e.g.

```lua
local util = require('util');
local HTTP_STATUS = require('httpconsts.status').consts;
local UNPROCESSABLE_ENTITY = HTTP_STATUS.UNPROCESSABLE_ENTITY;
local NO_CONTENT = HTTP_STATUS.NO_CONTENT;

-- parser for 'content-type: application/lua'
local function parse()
    local env = {};
    local src, fn, ok, err;

    ngx.req.read_body();
    src = ngx.req.get_body_data();
    if not src then
        return nil, NO_CONTENT;
    end

    -- parse a content body as a lua script
    fn, err = util.eval( src, env );
    if not err then
        ok, err = pcall( fn );
        if ok then
            return env;
        end
    end

    return nil, UNPROCESSABLE_ENTITY, 'failed: ' .. err;
end

return parse;
```

