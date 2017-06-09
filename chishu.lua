local cjson = require "cjson.safe"
local ssdb = require "gcs1.ssdb.utils"


local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1

local db = ssdb.get_ssdb_db()

local method = ngx.req.get_method()

if method ~= ngx.HTTP_GET then
    return ngx.exit(403)
end

local args = ngx.req.get_uri_args()

local data = db:get(args.postid)
local tb = cjson.decode(data)
if not tb then
    return ngx.exit(500)
end

if args.alarm == tb.alarm then
    return
end

tb.read_count = tb.read_count + 1

local str = cjson.encode(tb)
local ok,err = db:set(str.postid,str)
if not ok then
    ngx.say("failed to set postid:",err)
    return
end

ssdb.close_ssdb_db()
