local method = require "gcs1.info.fangfa"
local config_table = ngx.shared.gcs_config1
local Url = config_table:get("p_icoment_url")
local http = require "gcs1.http.http"
local cjson = require "cjson.safe"
local fireMethod = require "gcs1.account.firemethod"
local db_method = require "gcs1.db.method"
local commonUtils   = require "gcs1.account.common_utils"


local function table_concat(table)
    local res = {}
    for k, v in pairs(table) do
        if type(v) == "table" then
            for k1, v1 in pairs(v) do
                res[k1] = v1
            end
        else
            res[k] = v
        end
    end
    return res
end

local function shifou(value)
    if not value or value == "" or value == ngx.null then
        return "否"
    else
       if tonumber(value) == 1 then
           return "是"
       else
           return "否"
       end

    end
end
local function os_time(value)
    if not value or value == "" or value == ngx.null then
        return ""
    else
        local res = os.date("%Y-%m-%d",tonumber(value)/1000)
        return res
    end
end

local function webservice(uri)
	local hc = http:new()
	local res, err = hc:request_uri(uri, {
		method = "GET",
		headers = {["Content-Type"] = "application/json; charset=utf-8"}
		})
	return res, err
end

local time = ngx.time()
local timeEnd = os.date("%Y-%m-%d %H:%M:%S", tonumber(time))    --格式化时间
local timeStart = os.date("%Y-%m-%d %H:%M:%S", time-7200)    --格式化时间 2小时以前的
local timeStart = "2017-01-01 01:01:01"   --测试调用的参数
--local timeEnd = "2017-07-01 01:01:01"
local uri = "http://100.17.3.26:8080/pvas_web/getPaQieCases?"..ngx.encode_args({timeStart=timeStart})

local res, err = webservice(uri)

if not res or res.status ~= 200 then
    ngx.say(cjson.encode({resultcode = 1000, resultmessage = "连接疯狂接口失败:"..err}))
	return
end

local body, err = cjson.decode(res.body)
if not body or not next(body) then
	ngx.say(cjson.encode({resultcode = 1000, resultmessage = "json转table失败或table为空"..err}))
	return
end

local resp = body.resp --获取resp表   警情
if not resp or type(resp) ~= "table" or not next(resp) then
	ngx.say(cjson.encode({resultcode = 1000, resultmessage = "警情为空"}))
	return
end
--ngx.say(res.body)
--ngx.exit(200)
local create_unit = ""
local sql = "select code from tb_depart"
local res, err = db_method.query(sql)
if res and type(res) == "table" and next(res) then
    for _, v in pairs(res) do
        if create_unit == "" then
            create_unit = v.code
        else
            create_unit = create_unit .. "," .. v.code
        end
    end
end

local args = ngx.req.get_uri_args()
for _, v in ipairs(resp) do
    local qid = -1
    local value = config_table:incr("jingqing",1)
    if not value then
        config_table:set("jingqing",0)
    else
        qid = 0-value
    end
    local case_id = v.CASE_ID or ""   --案件id
    local case_name = v.CASENAME or ""    --案件名称
    local case_describe = v.SIMPLE_CASE_CONDITION or ""  --案件描述
    local report_time = os_time(v.REPORT_TIME)    --报案时间
    local discover_time = os_time(v.DISCOVER_TIME)  --发现时间
    local happen_address = v.HAPPEN_ADDR or ""   --案件地址
    local case_address = happen_address
    local belong_area = v.BENLONG_RESPON_REGION or "" --所属责任区
    --local has_site_number = v.HAS_SITE or "" --是否有现场  编号
    local has_site = shifou(v.HAS_SITE)
    
    --local has_kancha_number = v.HAS_KANCHA or "" --是否勘察现场  编号
    local has_kancha = shifou(v.HAS_KANCHA)

    local total_value = v.TOTAL_VALUE or "" --涉案总价值
    
    local economy_lose = v.ECONOMY_LOST or ""  --经济损失
    local hurt_num = v.HURT_NUM or "" --受伤人数
    local death_num = v.DIE_NUM or "" --死亡人数
    local case_tool = ""    --作案工具
    local case_method = ""  --作案手段
    local case_code = v.CASE_CODE or ""  --案件编号

    local case_type = "未知"
    local case_type_number = v.LEIBIE  --案件类型  编号   --需要判断
    if case_type_number and case_type_number ~= "" and case_type_number ~= ngx.null then
        local sql = "SELECT ITEM1 FROM tb_case_type WHERE CODE = " .. ngx.quote_sql_str(case_type_number)
        local res, err = db_method.query(sql)
        if not res then
            case_type = "未知"
        else
            case_type = res[1]["ITEM1"] or "未知"
        end
    end

    --local is_special_case = v.IS_SPECIAL_CASE or ""  --是否专案
    local is_special_case = shifou(v.IS_SPECIAL_CASE)

    --local case_status_string = v.CASE_STATUS or "" --案件状态  --需要判断
    local case_status = method.bianhao(v.CASE_STATUS)

    --local case_source = v.CASE_ORIGIN or "" --案件来源
    local case_source = method.laiyuan[v.CASE_ORIGIN] or ""
    --local case_source = method.laiyuan[v.CASE_ORIGIN] or ""
 
    local accept_type = method.shoulimethod[v.SHOULI_FANGSHI] or "" --受理方式
    
    local theme_keyword = v.THEME_KEYWORDS or "" --主题词

    --local zhishu_case = v.ZHISHU_ANJIAN or "" --直属案件 编号
    local zhishu_case = shifou(v.ZHISHU_ANJIAN)

    local report_people = v.REPORTER_NAME or "" --报警人姓名

    --local sex = v.REPORTER_GENDER or ""    --报警人性别  编号
    local sex = method.sex_number(v.REPORTER_GENDER) 

    --local birthday = v.REPORTER_BIRTHDAY or "" --报警人出生年月日
    local birthday = os_time(v.REPORTER_BIRTHDAY)

    local card_num = v.REPORTER_CARD_NO or ""  --报警人身份证号
    local unit = v.REPORTER_UNIT or ""  --报警人单位
    local phone_num = v.REPORTER_TEL or "" --报警人练习方式
    local address = v.REPORTER_ADDR or ""   --报警人住址

    --local accept_time = v.ACCEPT_TIME or ""  --受理时间戳
    local accept_time = os_time(v.ACCEPT_TIME)
   
    local accept_unit = v.ACCEPT_UNIT or "" --受理单位
    local accept_people = v.ACCEPT_PERSON or "" --受理人
    local accept_unit_phone = v.ACCEPT_UNIT_TEL or "" --受理单位电话
    local zhuban_unit = v.HOST_UNIT or ""      --主办单位
    local zhuban_people = v.HOST_PERSON or "" --主办人
    local zhuban_people_phone = v.ASSISTER_TEL or ""  --主办人电话
    local xieban_people = v.ASSISTER or ""    --协办人

    --local register_time = v.RECORD_TIME or ""    --登记时间戳
    local register_time = os_time(v.RECORD_TIME)

    local register_people = v.RECORD_PERSON or "" --登记人警号
    local jd = v.CASE_LONGITUDE --经度
    local wd = v.CASE_LATITUDE --纬度
    local H        --转换后的经度
    local W       --转换后的纬度
    if jd and wd then     
        local gps = {gps_h = jd, gps_w = wd}
        local gps_tb = fireMethod.fireGpsTrans(gps)
        H = gps_tb.gps_h
        W = gps_tb.gps_w
    else
    H = ""
    W = ""
    end
    local msg_content = {case_id = case_id, case_name = case_name, case_describe = case_describe, case_address = case_address, 
                         create_unit = create_unit, longtitude = H, latitude = W,
        case_base_info = {
            report_time = report_time, discover_time = discover_time, happen_address = happen_address, belong_area = belong_area,
            has_site = has_site, has_kancha = has_kancha, total_value = total_value, economy_lose = economy_lose,
            hurt_num = hurt_num, death_num = death_num, case_tool = case_tool, case_method = case_method
        },
        case_detail_info = {case_code = case_code, case_type = case_type, is_special_case = is_special_case, 
            case_status = case_status, case_source = case_source,
            accept_type = accept_type, theme_keyword = theme_keyword, zhishu_case = zhishu_case
        },
        case_people_info = {
            report_people = report_people, sex = sex, birthday = birthday, card_num = card_num,
            unit = unit, phone_num = phone_num, address = address
        },
        case_accept_info = {accept_time = accept_time, accept_unit = accept_unit, accept_people = accept_people,
            accept_unit_phone = accept_unit_phone, zhuban_unit = zhuban_unit, zhuban_people = zhuban_people,
            zhuban_people_phone = zhuban_people_phone, xieban_people = xieban_people, register_time = register_time,
            register_people = register_people
        }
    }
    local jingqing_tb = table_concat(msg_content)
    local jingqing = ""
    for k, v in pairs(jingqing_tb) do
        if jingqing == "" then
            jingqing = k .. "=" .. v
        else
            jingqing = jingqing .. "&" .. k .. "=" .. v
        end
    end
    local mode = args.mode
    local content = ""
    if  mode == "JQ" then
        content = jingqing
    end
    local sendnotice = args.msg or  "ceshihsishsih"
    local res, err = commonUtils.sendAllApns(sendnotice, mode, content)
    if not res  then
        ngx.log(ngx.ERR, "fadf:", err)
        ngx.exit(200)
    end

    local content = {CMD = 6, SID = "Iamnaruto", RID = "zjcisnaruto", MID = "2", TYPE = "B",
                     TIME = timeEnd, GPS = {H = H, W = W}, QID = qid,
                     MSG = {MTYPE = "JQ",CASE_DATA = msg_content, DATA = ""}
                    }
    local canshu = {}
    canshu.content = cjson.encode(content)
    local uri = "http://100.112.1.93:8000/broadcast?"..ngx.encode_args(canshu)   --自己的接口
    local res, err= webservice(uri)
    if not res or res.status ~= 200 then
        ngx.say(
                cjson.encode({
				              resultcode = 1000, resultmessage = "连接不上广播接口"..err
                             }) 
               )
        ngx.exit(200)
    end
ngx.sleep(1)
end

