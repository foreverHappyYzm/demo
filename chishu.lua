local ssdbMethod            = require "gcs1.ssdb.method"
local cjson                 = require "cjson.safe"
local dbMethod              = require "gcs1.db.method"
local utils                 = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"
local ssdb = require "gcs1.ssdb.utils"
local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1
local errsCollectJ      = userInfo:get("tb_err")
local errsT                 = cjson.decode(errsCollectJ)
local db = ssdb.get_ssdb_db()
local fangfa = ngx.req.get_method()
local args
if fangfa == "get" then
     args = ngx.req.get_uri_args()     --获取uri
     local neirong = db:get(args.postid)    --获取内容
     tb = cjson.decode(neirong) --    转换成表
     if args.alarm ~= tb.alarm then
     tb.read_count = tb.read_count + 1
     tb = cjson.encode(tb)
     local ok,err = db:set(tb.postid,tb)
          if not ok then
              ngx.say("failed to set postid:",err)
              return
          end
     end
end  
ssdb.close_ssdb_db()
