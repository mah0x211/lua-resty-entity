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


  lib/json.lua
  lua-resty-entity
  
  Created by Masatoshi Teruya on 14/06/30.

--]]

local decode = require('cjson.safe').decode;
local HTTP_STATUS = require('httpconsts.status').consts;
local UNPROCESSABLE_ENTITY = HTTP_STATUS.UNPROCESSABLE_ENTITY;
local NO_CONTENT = HTTP_STATUS.NO_CONTENT;

-- application/json
local function parse()
    local json, err, data;
    
    ngx.req.read_body();
    data = ngx.req.get_body_data();
    if not data then
        return nil, NO_CONTENT;
    end

    json, err = decode( data );
    if err then
        return nil, UNPROCESSABLE_ENTITY, 'failed to cjson.decode: ' .. err;
    end
    
    return json;
end


return parse;

