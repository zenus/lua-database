--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-5-28
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local clone = clone
local table_concat = table.concat
local table_remove = table.remove
local table_insert = table.insert
local table_sort = table.sort
local ngx_time = ngx.time
local string = require("DB.helper.string")
local cjson = require("cjson")
local randomseed = math.randomseed
local random = math.random
local setmetatable = setmetatable
local getmetatable = getmetatable


local _M = {}

local function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

local function merge(de, src)
   local dest = clone(de)
    for k, v in pairs (src) do
        if type(k) == 'string' then
            dest[k] = v
        else
            dest[#dest+1] = v
        end
    end
return dest
end

local function except(array,keys)
    for _,v in pairs(keys) do
        if array[v] then
            array[v]= nil
        end
    end
    return array
end

local function add(array,key,value)
    if not array[key] then
        array[key] = value
    end
    return array
end

local function get(array,key,value)
    return array[key] or value
end

local function map(callback,array)
   for k,v in pairs(array) do
       array[k] = callback(v)
   end
   return array
end

local function implode(sep,array)
    local result = {}
    for k,v in pairs(array) do
        result[#result+1] = v
    end
    return table_concat(result,sep)
end

local function count(array)

   local i = 0
    for k,v in pairs(array) do
        if  v then
            i = i + 1
        end
    end

    return i
end

local function is_array(array)

    if type(array) == 'table' then
        return true
    end

    return false
end

local function filter(array,callback)

    for k,v in pairs(array) do
        if not callback(v) then
            array[k] = nil
        end
    end

    return array
end

local function keys(array)
    local o = {}
    for k,v in pairs(array) do
        if v then
            o[#o+1] = k
        end
    end
    return o
end

local function values(array)
    local o = {}

    for k,v in pairs(array) do
        if v then
            o[#o+1] = v
        end
    end

    return o
end

local function fill(start_index, num, value)
    local o = {}
    local i = 1
    while i <= num do
        o[start_index+i] = value
        i = i + 1
    end
    return o
end

local function in_array(value,array)
    for _,v in pairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

local function unshift(array,value)
    return table_insert(array,1,value)
end


local function last(array)
    local array = array
   return table_remove(array)

end

local function combine(keys,values)
    local result = {}
   for i,k in ipairs(keys) do
       result[k] = values[i]
   end
   return result
end

local function slice(array,start,length,preserveKeys)
    local result = {}
    local i = 1
    local last = start + length - 1
    for k,v in pairs(array) do
        if i >= start and i <= last then
            result[k] = v
        end
        i = i + 1
    end
    return result
end


local function ksort(array)

    local keys = {}
    local result = {}
    for k in pairs(array) do
        keys[#keys+1] = k
    end
    table_sort(keys)
    for _,v in ipairs(keys) do
        result[v] = array[v]
    end

    return result
end

local function diff(array1,array2)
    for k,v in pairs(array1) do
        for _,vv in pairs(array2) do
            if v == vv then
                array1[k] = nil
            end
        end
    end
    return array1
end

local function fetch(_array,key)

    local keys = string.explode('.',key)

    local results = {}
    for _,segment in pairs(keys) do
        for k,value in pairs(_array) do
            if  type(value) ~= 'table' then
                value = {value}
            end
                results[#results+1] = value[segment]
        end
        _array = values(results)
    end

    return values(results)
end

--/**
--* Return the first element in an array passing a given truth test.
--*
--* @param  array    $array
--* @param  Closure  $callback
--* @param  mixed    $default
--* @return mixed
local function first(array,callback,default)
    for key,value in pairs(array) do
        local _,ret = pcall(callback,key,value)
        if ret then
            return ret
        end
    end
    return default
end


local function walk_recursive(input,funcname,userdata)

    if type(funcname) ~= 'function' then
        return false
    end

    if is_array(input) then
        return false
    end

    for key,value in pairs(input) do

       if is_array(input[key]) then

          input[key] =  walk_recursive(input[key],funcname,userdata)

       else

          local saved_value = value

           if count(userdata) > 0 then
               value = funcname(value,key,userdata)
           else
               value = funcname(value,key)
           end

           if value ~= saved_value then
               input[key] = value
           end
       end
    end

    return input
end

local function flatten(array)
    local result = {}
    walk_recursive(array,function(x) result[#result+1] = x end)
    return result
end

local function intersect(array1,array2)
    local result = {}
    for k,v in pairs(array1) do
        for _,vv in pairs(array2) do
            if v == vv then
                result[k] = v
            end
        end
    end
    return result

end

local function pluck(array,value,key)
   local results = {}
   for _,item in pairs(array) do
       local itemValue = item[value]
       if not key then
           results[#results+1] = itemValue
       else
           local itemKey = item[key]
           results[itemKey] = itemValue
       end
   end
   return results
end

local function reduce(array,callback,initial)
   local acc = initial
    for _,v in pairs(array) do
        acc = callback(acc,v)
    end
    return acc
end

local function rand(_array,num)
    randomseed(ngx_time())
    local count = count(_array)
    local i = 1
    local result = {}
    while i <= num do
        local key = random(count)
        if not result[key]  and  _array[key] then
            result[key] = _array[key]
            i = i + 1
        end
    end
    return result
end

local function flip(array)
    local result = {}
    for k,v in pairs(array) do
        result[v] = k
    end
    return result
end

local function intersect_key(array1,array2)
    local result = {}
    for k,v in pairs(array1) do
        for kk,vv in pairs(array2) do
            if k == kk then
                result[k] = v
            end
        end
    end
    return result
end

local function reverse(_array)
    local result = {}
    for i=1, #_array do
        result[i] = table_remove(_array)
    end
    local keys = {}
    for k,v in pairs(_array) do
        keys[#keys+1] = k
    end
    local len = #keys
    while len > 0 do
        local key = keys[len]
        result[key] = _array[key]
        len = len - 1
    end
    return result
end

local function shift(array)

    for k,v in pairs(array) do
        array[k] = nil
        return k,v
    end

end

local function chunk(input,size)

    local chunks = {}
    local i = 0
    local j = 0
    for key,value in pairs(input) do

        if not chunks[i] then
            chunks[i] = {}
        end

        if count(chunks[i]) < size then
            chunks[i][key] = value
        else
            i = i + 1
            chunks[i][key] = value
        end
        j = j + 1
    end

    return  chunks

end

local function asort(array)
    table_sort(array)
    return array
end

local function arsort(array)
    table_sort(array,function(a,b) return a > b end)
    return array
end

local function splice(array,start,length,replacement)
        local result = {}
        local i = 1
        local last = start + length - 1
        for k,v in pairs(array) do
            if i >= start and i <= last then
                if type(replacement) == 'table' then
                    for kk,vv in pairs(replacement) do
                        result[k] = vv
                        replacement[kk] = nil
                    end
                else
                    result[k] = replacement
                end
            end
            i = i + 1
        end
        return result
end

local function unique(array)
    local values = {}
    for k,v in pairs(array) do
        if values.v then
            array[k] = nil
        else
           values[v] = true
        end
    end
    return array
end

local function reset(array)
    for k,v in pairs(array) do
        return v
    end
end

_M.merge = merge
_M.reverse = reverse
_M.unique = unique
_M.except = except
_M.reduce = reduce
_M.splice = splice
_M.add = add
_M.get = get
_M.map = map
_M.implode = implode
_M.count = count
_M.is_array = is_array
_M.filter = filter
_M.keys = keys
_M.fill = fill
_M.in_array = in_array
_M.values = values
_M.last = last
_M.pop = last
_M.combine = combine
_M.slice = slice
_M.ksort = ksort
_M.arsort= arsort
_M.asort= asort
_M.diff = diff
_M.fetch = fetch
_M.first = first
_M.walk = walk
_M.walk_recursive = walk_recursive
_M.flatten = flatten
_M.intersect = intersect
_M.intersect_key = intersect_key
_M.pluck = pluck
_M.unshift = unshift
_M.rand = rand
_M.flip = flip
_M.reverse = reverse
_M.shift = shift
_M.chunk = chunk
_M.reset = reset
_M.clone = clone

return _M


