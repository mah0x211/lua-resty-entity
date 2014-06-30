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


  entity.lua
  lua-resty-entity
  
  Created by Masatoshi Teruya on 14/06/30.

--]]

local constants = require('resty.entity.constants');
local OK = constants.OK;
local UNSUPPORTED_MEDIA_TYPE = constants.UNSUPPORTED_MEDIA_TYPE;
local INTERNAL_SERVER_ERROR = constants.INTERNAL_SERVER_ERROR;
local NO_CONTENT = constants.NO_CONTENT;
local PARSER = {
    ['application/x-www-form-urlencoded'] = require('resty.entity.form'),
    ['multipart/form-data'] = require('resty.entity.multipart'),
    ['application/json'] = require('resty.entity.json')
};


-- get request table
local function get()
    local entity = rawget( ngx.ctx, 'entity' );
    
    if not entity then
        local method = ngx.req.get_method();
        
        entity = {
            docroot = ngx.var.document_root,
            method = method,
            scheme = ngx.var.scheme,
            uri = ngx.var.uri,
            query = ngx.req.get_uri_args(),
            header = ngx.req.get_headers()
        };
        rawset( ngx.ctx, 'entity', entity );
    end
    
    return entity;
end


-- get entity-body
local function getBody( ... )
    local rc, req = OK, getEntity();
    local err;
    
    if not rawget( req, 'body' ) then
        local ctype, clen = ngx.var.http_content_type, ngx.var.content_length;
        local body = {};
        
        if ctype and clen then
            local parser;
            
            ctype = ctype:match('^[^;]+');
            parser = PARSER[ctype];
            if parser then
                rc, body, err = parser( ... );
                -- invalid status-code
                if not rc or not constants.toString( rc ) then
                    rc = INTERNAL_SERVER_ERROR;
                    err = ('parser should return valid http status code' );
                end
            -- unsupported content-type
            else
                rc = UNSUPPORTED_MEDIA_TYPE;
            end
        -- no content
        else
            rc = NO_CONTENT;
        end
        
        rawset( req, 'body', body );
    end
    
    return rc, req, err;
end


-- rewrite entity-body parser
local function setBodyParser( tbl )
    if ngx.get_phase() ~= 'init' then
        error( 'must be call on init phase' );
    else
        local ctype, fn;
        
        for ctype, fn in pairs( tbl ) do
            if type( ctype ) ~= 'string' then
                error( 'content-type must be type of string' );
            -- remove parser
            elseif fn == false then
                rawset( PARSER, ctype, nil );
            -- check parser
            elseif type( fn ) ~= 'function' then
                error( 'parser must be type of function' );
            -- register parser
            else
                rawset( PARSER, ctype, fn );
            end
        end
    end
end


return {
    get = get,
    getBody = getBody,
    setBodyParser = setBodyParser,
};