--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-7
-- Time: 上午7:50
-- To change this template use File | Settings | File Templates.
--
local pairs = pairs
local type = type
local table_concat = table.concat
local string_format = string.format
local string_lower = string.lower
local string_find = string.find
local string_gmatch = string.gmatch
local string_match = string.match
local string_sub = string.sub
local string_len = string.len
local string_upper = string.upper
local ngx_gsub = ngx.re.gsub
local ngx_gmatch = ngx.re.gmatch
local ngx_sub = ngx.re.sub
local tonumber = tonumber

local _M = {}

local function in_array(value,array)
    for _,v in pairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

local function sprintf(fmt,...)
    return string_format(fmt,...)
end

local function strtolower(string)
    return string_lower(string)
end

local function strpos(string, needle,offset)
    offset  = offset or 1
    local spec_list ={"'",'.','%','+','-','*','?','[',']','^','$','(',')'}
    if in_array(needle,spec_list) then
        needle = '%'.. needle
    end
    return string_find(string,needle,offset)
end

local function explode(sep, string)
    local spec_list ={"'",'.','%','+','-','*','?','[',']','^','$','(',')'}
    if in_array(sep,spec_list) then
        sep = '%'.. sep
    end
    local pattern = "([^"..sep.."]+)"
    local t = {}
    for k, v in string_gmatch(string, pattern) do
        t[#t+1] = k
    end
    return t
end

local function trim(string,charlist)
    charlist = charlist or "%s%c"
    local pattern = "^[" ..charlist.."]*(.*)[" ..charlist.."]*$";
    return string_match(string,pattern)
end

local function ltrim(string,charlist)
    charlist = charlist or "%s%c"
    local pattern = "^[" ..charlist.."]*(.*)$";
    return string_match(string,pattern)
end

local function ucfirst(string)
    return string_upper(string_sub(string,1,1)) .. string_sub(string,2)
end

local function preg_replace(pattern, replacement, subject, limit, count )
   limit = limit or -1
   if limit ==1 then
       return ngx_sub(subject,pattern,replacement)
   else
       return ngx_gsub(subject,pattern,replacement)
   end
end

local function substr(string, start, length)
    return string_sub(string,start,length)
end

local function is_string(string)
    if type(string) == 'string' then
        return true
    end
    return false
end

local function tonumber(string)

    return tonumber(string)

end

local function snake_case(string, delimiter)
   delimiter = delimiter or '_'
   local replace = '$1'.. delimiter ..'$2'
   return  strtolower(preg_replace('/(.)([A-Z])/', replace, string))
end

local function preg_split(pattern,subject)
    local result = {}
    local pattern = "([^".. pattern .."]+)"
    for str in ngx_gmatch(subject,pattern) do
       result[#result+1] = str
    end

    return result
end



_M.sprintf = sprintf
_M.strtolower = strtolower
_M.strpos = strpos
_M.explode = explode
_M.trim = trim
_M.ltrim = ltrim
_M.ucfirst = ucfirst
_M.preg_replace = preg_replace
_M.substr = substr
_M.is_string = is_string
_M.tonumber = tonumber
_M.snake_case = snake_case
_M.preg_split = preg_split

return _M
