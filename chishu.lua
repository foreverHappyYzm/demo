local ssdbMethod = require "gcs1.ssdb.method"
local cjson = require "cjson.safe"
local dbMethod = require "gcs1.db.method"
local utils = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"
local ssdb = require "gcs1.ssdb.utils"
local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1
local db = ssdb.get_ssdb_db()
local fangfa = ngx.req.get_method()
if fangfa == "get" then
local args = ngx.req.get_uri_args()
local neirong = db:get(args.postid)
local tb = cjson.decode(neirong)
if args.alarm ~= tb.alarm then
tb.read_count = tb.read_count + 1
local tb = cjson.encode(tb)
local ok,err = db:set(tb.postid,tb)
if not ok then
ngx.say("failed to set postid:",err)
return
end
end
end  
ssdb.close_ssdb_db()
