local method = ngx.req.get_method()

if method ~= ngx.HTTP_GET then
    return ngx.exit(403)
end

local args = ngx.req.get_uri_args()

if not args then
    ngx.say("没有数据")
    return ngx.exit(403)
end

local k = args.k

local t = args.t

local time = ngx.time()

--local http = ngx.var.host_name
--local path = ngx.var.request_uri
--local url = http..path
local url = ngx.var.uri
local md5 = ngx.md5("secred"..url..t)

if t < time then
    return ngx.exit(403)
end

if k ~= md5 then
    return ngx.exit(403)
end
