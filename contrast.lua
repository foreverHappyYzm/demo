local method = ngx.req.get_method()
local args

if method == ngx.HTTP_GET then
    args = ngx.req_get_uri_args()
elseif method == ngx.HTTP_POST then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
else
--boolean
end

local k = args.k

local t = args.t

local time = ngx.time()

local md5 = ngx.md5("secred"..args.path..t) --args.path不知道是不是uri

if t < time then
    return ngx.exit(403)
end

if k ~= md5 then
    return ngx.exit(403)
end
