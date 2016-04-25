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
-- module
local toStatusLineName = require('httpconsts.status').toStatusLineName;
local HTTP_STATUS = require('httpconsts.status').consts;
-- constants
local NOT_ACCEPTABLE = HTTP_STATUS.NOT_ACCEPTABLE;
local UNSUPPORTED_MEDIA_TYPE = HTTP_STATUS.UNSUPPORTED_MEDIA_TYPE;
local INTERNAL_SERVER_ERROR = HTTP_STATUS.INTERNAL_SERVER_ERROR;
local NO_CONTENT = HTTP_STATUS.NO_CONTENT;
local PARSER = {
    ['application/x-www-form-urlencoded'] = require('resty.entity.form'),
    ['multipart/form-data'] = require('resty.entity.multipart'),
    ['application/json'] = require('resty.entity.json')
};
local ACCEPT_ENTITY_BODY = {
    POST = true,
    PUT = true
};
local EPARSER = 'incorrect parser implementation: %q';
-- class
local Entity = require('halo').class.Entity;


-- add/rewrite entity-body parser
function Entity.setBodyParser( tbl )
    if ngx.get_phase() ~= 'init' then
        error( 'must be call on init phase' );
    else
        for ctype, fn in pairs( tbl ) do
            if type( ctype ) ~= 'string' then
                error( 'content-type must be type of string' );
            -- remove parser
            elseif fn == false then
                PARSER[ctype] = nil;
            -- check parser
            elseif type( fn ) ~= 'function' then
                error( 'parser must be type of function' );
            -- register parser
            else
                PARSER[ctype] = fn;
            end
        end
    end
end


-- get request table
function Entity:init( ... )
    self.method = ngx.req.get_method();
    self.scheme = ngx.var.scheme;
    self.uri = ngx.var.uri;
    self.request_uri = ngx.var.request_uri;
    self.query = ngx.req.get_uri_args();
    self.header = ngx.req.get_headers();
    
    -- add accept entity body methods
    for idx, method in ipairs({...}) do
        if type( method ) ~= 'string' then
            error(
                ('method#%d must be string: %s'):format( idx, type( method ) )
            )
        end
        ACCEPT_ENTITY_BODY[method:upper()] = true;
    end
    
    return self;
end


-- get entity-body
function Entity:getBody( ... )
    if not ACCEPT_ENTITY_BODY[self.method] then
        return nil, NOT_ACCEPTABLE;
    -- already received
    elseif self.body then
        return self.body;
    elseif ngx.var.http_content_type then
        local ctype = ngx.var.http_content_type:match('[^%s;]+');
        local parser = ctype and PARSER[ctype];
        
        -- unsupported content-type
        if not parser then
            return nil, UNSUPPORTED_MEDIA_TYPE;
        elseif ngx.var.content_length then
            local body, rc, err = parser( ... );
            
            if body then
                self.body = body;
                return body;
            -- invalid status-code
            elseif not toStatusLineName( rc ) then
                return nil, INTERNAL_SERVER_ERROR, EPARSER:format( ctype );
            end
            
            return nil, rc, err;
        end
    end
    
    return nil, NO_CONTENT;
end

return Entity.exports;
