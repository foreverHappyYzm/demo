local http = require "resty.http"
local cjson = require "cjson"
local mysql = require "resty.mysql"
local tb = require "table.lua"




local db, err = mysql:new()       --实质化数据库
if not db then  
    ngx.say("new mysql error : ", err)  
    return  
end

db:set_timeout(1000)

local props = {                --连接数据库
    host = "100.112.1.83",  
    port = "3306",  
    database = "wz1",  
    user = "root",  
    password = "gcstorage"  
}  

local res, err, errno, sqlstate = db:connect(props)  

if not res then  
   ngx.say("connect to mysql error :err:", err, "errno:", errno, "sqlstate:", sqlstate)
   return
end

local httpc = http:new()

local function query(sql)
	local res, err, errno, sqlstate = db:query(sql)
    if not res then  
       ngx.say("select error :err:", err, "errno:", errno, "sqlstate:", sqlstate)  
       return db:close()
    end
    
    local value
    for _, table in ipairs(res) do
    	for _, v in pairs(table) do
    		value = v
    	end
    end

    return value
end
    		

local function get_msg(uri, timeStart, timeEnd)
    local res, err = httpc:request_uri(uri, {
	    method = "GET",
	    path = "?timeStart=" .. timeStart.."&"..timeEnd
	})
    if not res then
	    ngx.say("failed to request:", err)
	    return nil
    end

    return res
end

local a = ngx.time()
local timeEnd = os.date("%Y-%m-%d %H:%M:%S", tonumber(a))    --格式化时间
local b = tonumber(a) - 7200
local timeStart = os.date("%Y-%m-%d %H:%M:%S", b)    --格式化时间 2小时以前的


local uri = "http://100.112.0.142:8090/pvas_web/getPaQieCases"
local res = get_msg(uri, timeStart, timeEnd)
if res == ngx.null then
	ngx.say("res is empty")
	return
end

local body = res.body  --获取body
local body_tb = cjson.decode(body)
local resp_tb = body_tb.resp --获取resp表
for _, v in ipairs(resp_tb) do
    local a = v.CASE_PROVINCE   --省号邮编
    local b = v.CASE_CITY       --市编码
    local c = v.CASE_REGION     --区编号
    local sql_a = "select region_name from region_dict where region_code =" .. a
    local sql_b = "select region_name from region_dict where region_code =" .. b
    local sql_c = "select region_name from region_dict where region_code =" .. c
    local value_a = query(sql_a)
    local value_b = query(sql_b)
    local value_c = query(sql_c)
    local area = value_a .. value_b .. value_c    --发生区域
    local t = v.REPORT_TIME    --发生时间戳
    local time = os.date("%Y-%m-%d", t)  --格式化， 发生时间
    local s = v.CASE_STATUS   --案件状态码
    local status = tb(s)      --案件状态
    local number = v.CASE_CODE  --案件编号
    local location = v.HAPPEN_ADDR   --案件地址
    local describe = v.SIMPLE_CASE_CONDITION  --案件描述
    local casename = v.CASENAME    --案件名称
    local site = v.HAPPEN_ADDR   --具体地点
    local msg_content = {casename = casename, describe = describe, location = location, number = number, 
    status = status, time = time, area = area, site = site}
    local content = {CMD = 1, TYPE = "B", GPS = {H = "", W = ""}, MSG = {MTYPE = "T", DATA = msg_content}}
    local res, err = httpc:request_uri(uri, {
    	method = "GET",
    	path = "/broadcast?content="..cjson.encode(content)
    	})
    if not res then
        ngx.say("failed to request: ", err)
        return
    end
end