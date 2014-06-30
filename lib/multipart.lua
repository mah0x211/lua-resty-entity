--[[
  
  Copyright (C) 2014 Masatoshi Teruya
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.


  lib/multipart.lua
  lua-resty-entity
  
  Created by Masatoshi Teruya on 14/06/30.

--]]

local upload = require('resty.upload');
local util = require('util');
local constants = require('resty.entity.constants');
local OK = constants.OK;
local INTERNAL_SERVER_ERROR = constants.INTERNAL_SERVER_ERROR;
local BAD_REQUEST = constants.BAD_REQUEST;
local REQUEST_ENTITY_TOO_LARGE = constants.REQUEST_ENTITY_TOO_LARGE;
local DEFAULT = {
    -- path of upload file directory
    TMPDIR = '/tmp',
    -- prefix of temporary filename
    PREFIX = 'entity-',
    -- read timeout
    TIMEOUT = 1000,
    -- read buffer-size
    BUFLEN = 4096,
    -- max file-size
    MAXLEN = 1024
};


local function pathNormalize( ... )
    local argv = {...};
    local path = argv[1];
    local seg = nil;
    local res = {};
    
    if #argv > 1 then
        path = table.concat( argv, '/' );
    end
    
    -- remove double slash
    path = path:gsub( '/+', '/' );
    for seg in string.gmatch( path, '[^/]+' ) do
        if seg == '..' then
            table.remove( res );
        elseif seg ~= '.' then
            table.insert( res, seg );
        end
    end
    
    return '/' .. table.concat( res, '/' );
end



local function rcvHeader( field, header )
    if not field then
        local k,v;
        
        field = {};
        -- split name="value"
        for k, v in header[2]:gmatch('([^%s]+)="?([^"]+)"?') do
            rawset( field, k:lower(), v );
        end
    else
        rawset( field, header[1]:lower():gsub( '-', '_' ), header[2] );
    end
    
    return field;
end


local function rcvBody( field, val )
    -- append value
    if not field.filename then
        field.val = field.val .. val;
    else
        local len = #val;
        local tmp, err;
        
        -- content-type header
        if not field.tmpfile and field.filename then
            field.bytes = 0;
            -- construct tmpfile pathname
            field.tmpfile = pathNormalize( cfg.TMPDIR, cfg.PREFIX ..
                                           ngx.now() .. '-' ..
                                           ngx.var.remote_addr .. 
                                           ngx.var.remote_port );
            -- create tmpfile
            field.fh, err = io.open( field.tmpfile, 'w+' );
            if err then
                return 'failed to create temporary file: ' .. err;
            end
        end
        
        -- write to file
        -- maximum bytes limit exceeded
        if field.bytes + len > cfg.MAXLEN then
            return REQUEST_ENTITY_TOO_LARGE;
        else
            tmp, err = field.fh:write( val );
            if err then
                return 'failed to write to temporary file: ' .. err;
            end
            field.bytes = field.bytes + len;
        end
    end
end


local function setFormField( form, field )
    local key = field.name;
    
    field.name = nil;
    util.table.set( form, key, field );
    -- close tmpfile
    if field.fn then
        field.fh:close();
        field.fh = nil;
    end
end


local function mergeConfig( cfg )
    local err;
    
    -- overwrite
    if cfg then
        local key, val, t, cval;
        
        for key, val in pairs( DEFAULT ) do
            cval = rawget( cfg, key:lower() );
            -- set default value
            if not cval then
                rawset( cfg, key, val );
            -- invalid type of value
            elseif type( cval ) ~= type( val ) then
                err = ('%s must be type of %s'):format( key:lower(), t );
                break;
            else
                rawset( cfg, key, cval );
            end
        end
    -- use default
    else
        cfg = DEFAULT;
    end
    
    return cfg, err;
end


local function parse( ... )
    local cfg, err = mergeConfig( ... );
    local rc, form = OK, {};
    
    if err then
        rc = INTERNAL_SERVER_ERROR;
    else
        local parser;
        
        -- create resty.upload instance
        parser, err = upload:new( cfg.BUFLEN );
        if not parser then
            rc = INTERNAL_SERVER_ERROR;
        else
            local field, state, key, val;
            
            parser:set_timeout( cfg.TIMEOUT );
            -- parse entity body
            while true do
                state, val, err = parser:read()
                -- got error
                if err then
                    rc = INTERNAL_SERVER_ERROR;
                    break;
                -- end-of-file stream
                elseif state == 'eof' then
                    break;
                -- found header
                elseif state == 'header' then
                    if type( val ) ~= 'table' then
                        err = 'found invalid request line: ' .. val;
                        rc = BAD_REQUEST;
                        break;
                    end
                    field = rcvHeader( field, val );
                -- found body
                elseif state == 'body' then
                    err = rcvBody( field, val );
                    if err then
                        rc = INTERNAL_SERVER_ERROR;
                        break;
                    end
                -- finish part
                elseif state == 'part_end' then
                    setFormField( form, field );
                    field = nil;
                end
            end
            
            -- cleanup on error
            if field then
                setFormField( form, field );
            end
        end
    end
    
    return rc, form, err;
end


return parse;

