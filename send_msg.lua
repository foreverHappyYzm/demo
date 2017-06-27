local http = require "resty.http"
local cjson = require "cjson"




local function get_msg(uri, timeStart, timeEnd)
  local httpc = http:new()
  local res, err = httpc:request_uri(uri, {
	method = "GET",
	path = "?timeStart=" .. timeStart.."&" ..timeEnd
	})
  if not res then
	  return ngx.exit(200)
  end

  return res
end

local a = ngx.time()
local timeEnd = os.date("%Y-%m-%d %H:%M:%S", tonumber(a))    --格式化时间
local b = tonumber(a) - 7200
local timeStart = os.date("%Y-%m-%d %H:%M:%S", b)    --格式化时间 2小时以前的

local uri = "http://100.112.0.142:8090/pvas_web/getPaQieCases"
local res = get_msg(uri, timeStart, timeEnd)

local res_tb = cjson.decode(res)  --转换成表
local body = res_tb.body  --获取body
local resp_tb = body.resp --获取resp表