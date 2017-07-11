local db_method = require "gcs1.db.method"
local http = require "gcs1.http.http"
local cjson = require "cjson.safe"
local method = require "gcs1.info.fangfa"
local tracker = require("resty.gcsdfs.tracker")
local storage = require "resty.gcsdfs.storage"




--连接接口获取数据
local function webservice(uri)
	local hc = http:new()
	local res, err = hc:request_uri(uri, {
	method = "GET",
	headers = {["Content-Type"] = "application/json; charset=utf-8"}
	})
	return res, err
end



--存储数据需要调用的函数
local function upload_file(file_str,format)
	local storageRes = {}
	storageRes.group_name = "tax00"
	storageRes.store_path_index = 0
	storageRes.host = "100.112.1.98"
	storageRes.port = 13100
	local storage_res = storageRes
	local st = storage:new()
	st:set_timeout(3000)
	
	local ok, err = st:connect(storage_res)
	if not ok then
		return nil,"failed to connect storage,err:"..err .. ",storage_res:" .. cjson.encode(storage_res)
	end
	if not format then
		format = "jpg"
	end
	--关闭storage
	local gfile1
	local res, err = st:upload_by_buff(file_str, format)
	if not res then
		return nil,err,1101    --错误码 待定义
	else
		gfile1 = res.group_name.."/"..res.file_name
	end
	st:set_keepalive("5000","100")
	
	return gfile1, err
end

--存储数据
local function file_new_address(url)
	if not url or url == "" then
		return nil,"url is empty!"
	end
	local format = url:match(".+%.(%w+)$")
	local res, err = webservice(url)
	if not res then
		return nil,err
	end
	if not format   then
		format  = "jpg"
	end
	if res.body ~= "" then
	    local gfile, err =  upload_file(res.body, "jpg")
	    if not gfile then
	        return nil, err
	    end
           
	    return gfile
	end
	return nil, " file body is empty! url is :" .. url
end

local max = {}   --最后反馈给前端的信息集合
local people_native = ""
local people_census = ""
local people_census_detail = ""
local people_present_address = ""
local profess_thief = ""
local team = ""
local case_count = ""
local active_area = ""
local team_status = ""
local case_type = ""
local capture_address = ""
local capture_unit = ""
local capture_department = ""
local handle_unit = ""
local handle_department = ""
local catch_time = ""
local catch_unit = ""
local modify_time = ""
local modify_unit = ""
local describe = ""
local people_whcd = ""

local args
if ngx.req.get_method() == "GET" then
    args= ngx.req.get_uri_args()
else
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    args = ngx.decode_args(body, 0)
end

local loadmore = args.loadmore or 0
local condition = args.condition or ""
local start_int = tonumber(loadmore)

local tb = {}
tb.param = condition
--tb.param = "周"
tb.startIndex = (start_int * 20)
--tb.startIndex = 0
tb.pageSize = 20
local canshu = ngx.encode_args(tb)
local uri = "http://100.17.3.26:8080/crimerepo/queryCrimerByParamsForWZ?" .. canshu
local res, err = webservice(uri)
if not res or res.status ~= 200 then
    max.resultcode = 1000
    max.resultmessage = "烽火接口调用失败"
    max.response = ""
    ngx.say(cjson.encode(max))
    ngx.exit(200)
end


local body = res.body
if not body or body == "" or body == ngx.null then
    max.resultcode = 1000
    max.resultmessage = "响应体为空"
    max.response = ""
    ngx.say(cjson.encode(max))
    ngx.exit(200)
end

local body_tb,err = cjson.decode(body)   --转换成表
if not body_tb or not next(body_tb) then
    max.resultcode = 1000
    max.resultmessage = "json转table失败,或空table"
    max.response = ""
    ngx.say(cjson.encode(max))
    ngx.exit(200)
end

local content_tb = body_tb.crimers   --查询到的信息都包含在这个crimers字段中，每个人的信息是单独的子表
if not next(content_tb) then
    ngx.say(cjson.encode({resultcode = 1000, resultmessage = "个人信息为空"}))
    return
end

local response = {} --返回的信息
for _, v in pairs(content_tb) do		
    local xm = v.xm or ""  --姓名string
    local sex = v.xb or "" --性别编号
    local birthday = v.chusny or "" --出生年月string
    local car = v.shfzhh or ""  --身份证号string
    
    local mz
    local mz_str = v.mz--民族string
    if not mz_str or mz_str == "" or mz_str == ngx.null then
        mz = ""
    else
        mz = method.mzbh(mz_str)
    end

    local photo_data_tb = v.zxzhp1FileManage   --图片信息表
    local src
    if next(photo_data_tb) then
        local fileid = photo_data_tb.fileId   --获取图片id码
        if not fileid or fileid == "" or fileid == ngx.null then
            src = ""
        else
            local url = "http://100.17.3.26:8080/crimerepo/queryCrimerByParamsForWZ.do?" .. ngx.encode_args({fileId = fileid})  
            local res, err = file_new_address(url)   --得到图片流并存储到tax
            if not res or res == "" or res == ngx.null then
                src = ""
            else
                src = "http://113.57.174.98:13201/" .. res
            end

        end
    else
       src = ""
    end
        
    local fzrid = v.fzrId --详情查询字段
    if fzrid and fzrid ~= "" or fzrid ~= ngx.null then
        local url = "http://100.17.3.26:8080/crimerepo/getCrimerDetailInfoByFzrIdForWZ?" .. ngx.encode_args({fzrId = fzrid})
        local res, err = webservice(url)   --调用http客户端函数
        if res and res.status == 200 and type(cjson.decode(res.body)) and next(cjson.decode(res.body)) then  --确定是否有响应体
            local crimer = body.crimer  --crimer字段下包含详细信息
            if type(crimer) and next(crimer) then   --判断详细信息表是否为空
                local native = crimer.jg  --籍贯
                if native and native ~= "" and native ~= ngx.null then
                    local sql = "select REGION_NAME from tb_youbian where REGION_CODE ="..tonumber(native)
                    local res, err = db_method.query(sql)   --连接数据库
                    if res then
                        people_native = res[1]["REGION_NAME"]
                    end

                end
    
                local census = crimer.hjszdSh  --户籍
                if census and census ~= "" and census ~= ngx.null then
                    local sql = "select REGION_NAME from tb_youbian where REGION_CODE ="..tonumber(census)
                    local res, err = db_method.query(sql)
                    if res then
                        people_census = res[1]["REGION_NAME"]
                    end

                end
					
			    people_census_detail = crimer.hjszdXxdzh or ""
	            people_present_address = crimer.xzhzhXxdzh or ""
	            profess_thief = crimer.sfzhp or ""
	            team = crimer.sshth or ""
	            active_area = crimer.jchdqy or ""
                people_whcd = crimer.whchd or ""                    
            end
        end
    end
    
	table.insert(response, {casepeopleinfo =  {people_name = xm, people_sex = sex, people_birth = birthday, people_card_number = car, 
                                               people_nation = mz, people_native = people_native, people_census = people_census, 
                                               people_census_detail = people_census_detail, 
                                               people_present_address = people_present_address,people_whcd = people_whcd
                                              }, 
                            caseinfo = {profess_thief = profess_thief, team = team, case_count = case_count, 
                                        active_area = active_area, team_status = team_status, case_type = case_type, 
                                        capture_address = capture_address, capture_unit = capture_unit,
                                        capture_department = capture_department
                                       }, 
                            more = {handle_unit = handle_unit, handle_department = handle_department, catch_time = catch_time, 
                                    catch_unit = catch_unit, modify_time = modify_time, modify_unit = modify_unit, describe = describe
                                   }, 
                            pics ={src}
                           }
                )
end
local max = {resultcode = 0, resultmessage = "正常", response = response}

ngx.say(cjson.encode(max))
