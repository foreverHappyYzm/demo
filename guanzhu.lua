local ssdbMethod            = require "gcs1.ssdb.method"
local cjson                 = require "cjson.safe"
local dbMethod              = require "gcs1.db.method"
local utils                 = require "gcs1.utils"
local commonUtils   = require "gcs1.account.common_utils"


local config = ngx.shared.gcs_config1
local userInfo = ngx.shared.userinfo1

local MODULE_NAME = "focuswork:"

local args = commonUtils.getArgsMethod()
local self = args.alarm                
local focusedNum = args.focusalarm  
local selfzname = "focus_" .. self   
local fanszname = focusedNum.."_focus"      
if args.action == "setfocus" then       
  local time = ngx.time()     
  local setres, err = ssdbMethod.zset_data(selfzname, focusedNum, time) 
  local setres, err = ssdbMethod.zset_data(fanszname, self, time)
end

if args.action == "delfocus" then       
    local time = ngx.time()             
    local delres, err = ssdbMethod.zdel_data(selfzname, focusedNum)
    local delres, err = ssdbMethod.zdel_data(fanszname, self)
end
