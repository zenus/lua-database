--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-7
-- Time: 上午6:45
-- To change this template use File | Settings | File Templates.
--

local array = require("DB.helper.array")
local pairs = pairs
local string = require("DB.helper.string")
local class = require("DB.helper.class")
local cjson = require("cjson")
local BaseGrammar = class.create('BaseGrammar')
--BaseGrammar.__index = BaseGrammar
--BaseGrammar.tablePrefix = ''


function BaseGrammar:__construct()
    self.tablePrefix = ''
end


--/**
--* Wrap an array of values.
--*
--* @param  array  $values
--* @return array
--        */
function BaseGrammar:wrapArray(values)

    local callback = function(value)
        return self:wrap(value)
    end

    return array.map(callback, values);
end


--/**
--* Wrap a table in keyword identifiers.
--*
--* @param  string  $table
--* @return string
--*/
function BaseGrammar:wrapTable(table)
   if self:isExpression(table) then
       return self:getValue(table)
   end
   return self:wrap(self.tablePrefix .. table)
end
--
--/**
--* Wrap a value in keyword identifiers.
--*
--* @param  string  $value
--* @return string
--*/
function BaseGrammar:wrap(value)
    if self:isExpression(value) then
        return  self:getValue(value)
    end
        --// If the value being wrapped has a column alias we will need to separate out
        --// the pieces so we can wrap each of the segments of the expression on it
        --// own, and then joins them both back together with the "as" connector.
    if string.strpos(string.strtolower(value),'as') then
       local segments = string.explode(' ',value)
--       ngx.say(cjson.encode(segments))
       return self:wrap(segments[1]) .. 'as' .. self:wrap(segments[3])
    end
    local wrapped = {}
    local segments = string.explode('.',value)
    --// If the value is not an aliased table expression, we'll just wrap it like
    --// normal, so if there is more than one segment, we will wrap the first
    --// segments as if it was a table and the rest as just regular values.
    for key, segment in pairs(segments) do
        if key == 1 and array.count(segments) > 1 then
--                   ngx.say(cjson.encode(segments))
            wrapped[key] = self:wrapTable(segment)
        else
            wrapped[key] = self:wrapValue(segment)
        end
    end
    return array.implode('.', wrapped)
end

--
--/**
--* Wrap a single string in keyword identifiers.
--*
--* @param  string  $value
--* @return string
--*/
function BaseGrammar:wrapValue(value)
--    ngx.say(self.wrapper)
    return value ~= '*' and string.sprintf(self.wrapper,value) or value
end

--/**
--* Convert an array of column names into a delimited string.
--*
--* @param  array   $columns
--* @return string
--*/
function BaseGrammar:columnize(columns)
    local callback = function(column)
        return self:wrap(column)
    end
    return array.implode(',',array.map(callback,columns))
end
--
--/**
--* Create query parameter place-holders for an array.
--*
--* @param  array   $values
--* @return string
--*/
function BaseGrammar:parameterize(values)
    local callback = function(value)
        return self:parameter(value)
    end
    return array.implode(',',array.map(callback,values))
end
--
--/**
--* Get the appropriate query parameter place-holder for a value.
--*
--* @param  mixed   $value
--* @return string
--*/
function BaseGrammar:parameter(value)
    return self:isExpression(value) and self:getValue(value) or '?'
end
--
--/**
--* Get the value of a raw expression.
--*
--* @param  \Illuminate\Database\Query\Expression  $expression
--* @return string
--*/
function BaseGrammar:getValue(expression)
    return expression:getValue()
end
--
--/**
--* Determine if the given value is a raw expression.
--*
--* @param  mixed  $value
--* @return bool
--*/
function BaseGrammar:isExpression(value)

    return class.instanceof(value,'Expression')
end
--/**
--* Get the format for database stored dates.
--*
--* @return string
--*/
function BaseGrammar:getDateFormat()
    return 'Y-m-d H:i:s'
end
--
--/**
--* Get the grammar's table prefix.
--*
--* @return string
--*/
function BaseGrammar:getTablePrefix()
    return self.tablePrefix
end
--
--/**
--* Set the grammar's table prefix.
--*
--* @param  string  $prefix
--* @return \Illuminate\Database\Grammar
--*/
function BaseGrammar:setTablePrefix(prefix)
    self.tablePrefix = prefix
    return self
end


return BaseGrammar

