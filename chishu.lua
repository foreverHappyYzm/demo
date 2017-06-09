local ssdbMethod = require "gcs1.ssdb.method"
local cjson = require "cjson.safe"
local dbMethod = require "gcs1.db.method"
local utils = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"
local ssdb = require "gcs1.ssdb.utils"
--共享内存
local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1
--实质化对象
local db = ssdb.get_ssdb_db()
--获取请求方法
local method = ngx.req.get_method()
--判断是否为get请求
if method == "GET" then
    --获取geturi
    local args = ngx.req.get_uri_args()
    --获取发帖信息
    local data = db:get(args.postid)
    --转换成表
    local tb = cjson.decode(data)
    --判断操作人是否为发帖人
    if args.alarm ~= tb.alarm then
        --不是帖子浏览数加1
        tb.read_count = tb.read_count + 1
        --将新表转换成字符串形式
        local tb = cjson.encode(tb)
        --插入ssdb
        local ok,err = db:set(tb.postid,tb)
        if not ok then
            ngx.say("failed to set postid:",err)
            return
        end
    end
end
--关闭ssdb连接
ssdb.close_ssdb_db()
