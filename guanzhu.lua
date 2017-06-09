--调用模块
local ssdbMethod            = require "gcs1.ssdb.method"
local cjson                 = require "cjson.safe"
local dbMethod              = require "gcs1.db.method"
local utils                 = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"
--共享内存
local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1
--
local errsCollectJ      = userInfo:get("tb_err")
local errsT                 = cjson.decode(errsCollectJ)
local MODULE_NAME = "focuswork:"
--获取uri
local args = commonUtils.getArgsMethod()

local self = args.alarm                    --自己的警号

local focusedNum = args.focusalarm         --关注人警号

local selfzname = "focus_" .. self         --自己关注列表zname

local fanszname = focusedNum.."_focus"     --别人关注列表zname   

if args.action == "setfocus" then         --关注
  local time = ngx.time()              --时间
  
  local setres,err = ssdbMethod.zset_data(selfzname,focusedNum,time)
  
  local setres,err = ssdbMethod.zset_data(fanszname,self,time)
  --存数据
  local msgT = {}
  msgT.sid = args.alarm
  msgT.rid = focusedNum
  msgT.data = "有人关注了你"
  local gps = {}               --坐标表
  gps.H = "0"
  gps.W = "0"
  msgT.gps = gps
  msgT.cmd = "4"
  msgT.mtype = "9"
  msgT.type = "G"
    
  local sendMessageT,msg_maxT = commonUtils.makeMessage(msgT)
  local setmsgT = commonUtils.setMessage(sendMessageT,msg_maxT[1],focusedNum)
  local sendRes, err  = commonUtils.sendMessage(setmsgT, focusedNum)
  ngx.say(cjson.encode(errsT[8]))
  ngx.exit(200)
end

if args.action == "delfocus" then         --取消关注
    local time = ngx.time()               --时间
    local delres,err = ssdbMethod.zdel_data(selfzname,focusedNum)
    local delres,err = ssdbMethod.zdel_data(fanszname,self)
end
