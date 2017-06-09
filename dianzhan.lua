local ssdbMethod            = require "gcs1.ssdb.method"
local cjson                 = require "cjson.safe"
local dbMethod              = require "gcs1.db.method"
local utils                 = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"


local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1

local MODULE_NAME = "praise:"

local args = commonUtils.getArgsMethod()

local zname = args.postid .. "_praise"

local time = ngx.time() 

local key = args.alarm 

if args.action == "setpraise" then 
    local delCommentIdRes, err = ssdbMethod.zset_data(zname,key,time) 
    if not delCommentIdRes then
       ngx.say("err:", err)   --日志
       ngx.exit(200)
    end
    
    local getCount, err = ssdbMethod.zsize(zname) 
    local getFans, err = ssdbMethod.zkeys(zname,"","","",getCount) 
    if not getFans then
        ngxsay("error:", err) 
        ngx.exit(200)
    end
    
    if next(getFans) then  
        for _,v in pairs (getFans) do 
            local msgT = {sid = args.alarm, rid = v, data = "有人点赞", gps={H = "0", W = "0"}, cmd = "4",
                mtype = "8", type = "6"}           
            local sendMessageT, msg_maxT = commonUtils.makeMessage(msgT)                     
            local setmsgT = commonUtils.setMessage(sendMessageT, msg_maxT[1],v )         
            local sendRes, err  = commonUtils.sendMessage(setmsgT, v)
        end
    end
end

if args.action == "delpraise" then  
    local delPraiseRes, err = ssdbMethod.zdel(zname,key)   
    if not delPraiseRes then
         ngx.say("error:", err)  
         ngx.exit(200)
    end
end
