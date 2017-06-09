local ssdbMethod            = require "gcs1.ssdb.method"
local cjson                 = require "cjson.safe"
local dbMethod              = require "gcs1.db.method"
local utils                 = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"

local config = ngx.shared.gcs_config1     --共享对象
local userInfo = ngx.shared.userinfo1     --共享对象
local errsCollectJ      = userInfo:get("tb_err")   --获取tb_err
local errsT                 = cjson.decode(errsCollectJ)  --cjson 转换
local MODULE_NAME = "praise:"                      --变量                      
local args = commonUtils.getArgsMethod()           --获取 uri信息
local zname = args.postid .. "_praise"             --帖子id连接点赞字符串
local time = ngx.time()                            --时间
local key = args.alarm                             --获取点赞人警号
if args.action == "setpraise" then         --点赞
    local delCommentIdRes,err = ssdbMethod.zset_data(zname,key,time)   --插入数据
    if not delCommentIdRes then
       utils.gcs_log("error", MODULE_NAME .. " zset commentid is faile, err: " .. err)   --日志
       ngx.say(cjson.encode(errsT[7]))
       ngx.exit(200)
    end
    local setPraUser = args.postid .. "_praise"    --帖子id连接点赞字符串
    local getCount,err = ssdbMethod.zsize(setPraUser)  --返回元素的个数(知道点赞的次数)
    local getFans,err = ssdbMethod.zkeys(setPraUser,"","","",getCount)  --筛选列表  
    if not getFans then
        utils.gcs_log("error", MODULE_NAME .. ", get zname size is faile, err: " .. err)   --错误日志
        ngx.say(cjson.encode(errsT[7]))
        ngx.exit(200)
    end
    
    if next(getFans) then          --判断表是否为空
        for _,v in pairs (getFans) do    --遍历表
            local msgT = {}
            msgT.sid = args.alarm        --点赞人警号
            msgT.rid = v                 --遍历出来的点赞人警号
            msgT.data = "有人点赞"       --有人点赞
            local gps = {}             
            gps.H = "0"                  --赋值
            gps.W = "0"                  --赋值
            msgT.gps = gps               --赋值
            msgT.cmd = "4"               --赋值
            msgT.mtype = "8"             --赋值
            msgT.type = "G"              --赋值
            local sendMessageT, msg_maxT = commonUtils.makeMessage(msgT)                 --返回两个表        
            local setmsgT = commonUtils.setMessage(sendMessageT, msg_maxT[1],v )         
            local sendRes, err  = commonUtils.sendMessage(setmsgT, v)
        end
    end
    ngx.say(cjson.encode(errsT[8]))
    ngx.exit(200)
end
if args.action == "delpraise" then    --取消点赞
    local delPraiseRes,err = ssdbMethod.zdel(zname,key)     --删除数据
    if not delPraiseRes then
         utils.gcs_log("error", MODULE_NAME .. " zdel praise is faile, err: " .. err)    --日志
         ngx.say(cjson.encode(errsT[7]))
         ngx.exit(200)
    end
end
