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


  lib/constants.lua
  lua-resty-entity
  
  Created by Masatoshi Teruya on 14/06/30.

--]]
local Constants = require('halo').class.Constants;
local CODES = {
    -- 1xx infromational
    CONTINUE                            = 100,
    SWITCHING_PROTOCOLS                 = 101,
    -- WebDAV
    PROCESSING                          = 102,  -- WebDAV; RFC 2518
    -- /WebDAV
    
    -- 2xx successful
    OK                                  = 200,
    CREATED                             = 201,
    ACCEPTED                            = 202,
    NON_AUTHORITATIVE_INFORMATION       = 203,  -- since HTTP/1.1
    NO_CONTENT                          = 204,
    RESET_CONTENT                       = 205,
    PARTIAL_CONTENT                     = 206,
    -- WebDAV
    MULTI_STATUS                        = 207,  -- WebDAV; RFC 4918
    ALREADY_REPORTED                    = 208,  -- WebDAV; RFC 5842
    -- /WebDAV
    
    -- 3xx redirect
    MULTIPLE_CHOICES                    = 300,
    MOVED_PERMANENTLY                   = 301,
    FOUND                               = 302,
    SEE_OTHER                           = 303,  -- since HTTP/1.1
    NOT_MODIFIED                        = 304,
    USE_PROXY                           = 305,  -- since HTTP/1.1
    TEMPORARY_REDIRECT                  = 307,  -- since HTTP/1.1
    
    -- 4xx client error
    BAD_REQUEST                         = 400,
    UNAUTHORIZED                        = 401,
    PAYMENT_REQUIRED                    = 402,
    FORBIDDEN                           = 403,
    NOT_FOUND                           = 404,
    METHOD_NOT_ALLOWED                  = 405,
    NOT_ACCEPTABLE                      = 406,
    PROXY_AUTHENTICATION_REQUIRED       = 407,
    REQUEST_TIMEOUT                     = 408,
    CONFLICT                            = 409,
    GONE                                = 410,
    LENGTH_REQUIRED                     = 411,
    PRECONDITION_FAILED                 = 412,
    REQUEST_ENTITY_TOO_LARGE            = 413,
    REQUEST_URI_TOO_LONG                = 414,
    UNSUPPORTED_MEDIA_TYPE              = 415,
    REQUESTED_RANGE_NOT_SATISFIABLE     = 416,
    EXPECTATION_FAILED                  = 417,
    -- WebDAV
    UNPROCESSABLE_ENTITY                = 422,  -- WebDAV; RFC 4918
    LOCKED                              = 423,  -- WebDAV; RFC 4918
    FAILED_DEPENDENCY                   = 424,  -- WebDAV; RFC 4918
    -- /WebDAV
    UPGRADE_REQUIRED                    = 426,  -- RFC 2817
    PRECONDITION_REQUIRED               = 428,  -- RFC 6585
    TOO_MANY_REQUESTS                   = 429,  -- RFC 6585
    REQUEST_HEADER_FIELDS_TOO_LARGE     = 431,  -- RFC 6585
    
    -- 5xx server error
    INTERNAL_SERVER_ERROR               = 500,
    NOT_IMPLEMENTED                     = 501,
    BAD_GATEWAY                         = 502,
    SERVICE_UNAVAILABLE                 = 503,
    GATEWAY_TIMEOUT                     = 504,
    VERSION_NOT_SUPPORTED               = 505,
    VARIANT_ALSO_NEGOTIATES             = 506,  -- RFC 2295
    -- WebDAV
    INSUFFICIENT_STORAGE                = 507,  -- WebDAV; RFC 4918
    LOOP_DETECTED                       = 508,  -- WebDAV; RFC 5842
    -- /WebDAV
    BANDWIDTH_LIMIT_EXCEEDED            = 509,  -- Apache bw/limited extension
    NOT_EXTENDED                        = 510,  -- RFC 2774
    NETWORK_AUTHENTICATION_REQUIRED     = 511,  -- RFC 6585

    -- set methods
    M_GET         = ngx.HTTP_GET,
    M_HEAD        = ngx.HTTP_HEAD,
    M_PUT         = ngx.HTTP_PUT,
    M_POST        = ngx.HTTP_POST,
    M_DELETE      = ngx.HTTP_DELETE,
    M_OPTIONS     = ngx.HTTP_OPTIONS,
    M_MKCOL       = ngx.HTTP_MKCOL,
    M_COPY        = ngx.HTTP_COPY,
    M_MOVE        = ngx.HTTP_MOVE,
    M_PROPFIND    = ngx.HTTP_PROPFIND,
    M_PROPPATCH   = ngx.HTTP_PROPPATCH,
    M_LOCK        = ngx.HTTP_LOCK,
    M_UNLOCK      = ngx.HTTP_UNLOCK,
    M_PATCH       = ngx.HTTP_PATCH,
    M_TRACE       = ngx.HTTP_TRACE
};
-- set status-names
local NAMES = {};
do
    local k, v;
    for k, v in pairs( CODES ) do
        if not k:find( '^M_' ) then
            NAMES[tostring(v)] = k;
        end
    end
end

Constants.property( CODES );

function Constants.toString( val )
    return NAMES[tostring(val)];
end


function Constants.copy( tbl )
    local k, v;

    for k, v in pairs( CODES ) do
        tbl[k] = v;
    end
end


return Constants.exports;
