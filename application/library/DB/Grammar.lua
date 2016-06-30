--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-23
-- Time: 上午7:20
-- To change this template use File | Settings | File Templates.
--
local array = require("application.library.array")
local Expression = require("DB.Query.Expression")
local string = require("application.library.string")
local pairs = pairs
local Grammar = {}
Grammar.__index = Grammar

--
--    /**
--   * The grammar table prefix.
--*
--* @var string
--*/
Grammar.tablePrefix = ''
--
--/**
--* Wrap an array of values.
--*
--* @param  array  $values
--* @return array
--        */
function Grammar:wrapArray(values)
   local callback = function(value)
      return self:wrap(value)
   end
   return array.map(callback,values)
end

--
--/**
--* Wrap a table in keyword identifiers.
--*
--* @param  string  $table
--* @return string
--*/
function Grammar:wrapTable(table)
   if self:isExpression(table) then
      return self:getValue(table)
   end

   return self:wrap(self.tablePrefix..table)
end
--
--/**
--* Wrap a value in keyword identifiers.
--*
--* @param  string  $value
--* @return string
--*/
function Grammar:wrap(value)

   if self:isExpression(value) then
      return self:getValue(value)
   end
   --// If the value being wrapped has a column alias we will need to separate out
   --// the pieces so we can wrap each of the segments of the expression on it
   --// own, and then joins them both back together with the "as" connector.
   if string.strpos(string.strtolower(value),' as ') ~= false then
      local segments = string.explode(' ',value)
      return self:wrap(segments[1])..' as '..self:wrap(segments[3]);
   end

   local wrapped = {}

   local segments = string.explode('.',value)
   --// If the value is not an aliased table expression, we'll just wrap it like
   --// normal, so if there is more than one segment, we will wrap the first
   --// segments as if it was a table and the rest as just regular values.
   for key,segment in pairs(segments) do

      if key == 0 and array.count(segments) > 1 then

         wrapped[#wrapped+1] = self:wrapTable(segment)

      else

         wrapped[#wrapped+1] = self:wrapValue(segment)

      end
   end

   return array.implode('.', wrapped);

end
--
--/**
--* Wrap a single string in keyword identifiers.
--*
--* @param  string  $value
--* @return string
--*/
function Grammar:wrapValue(value)
   return value ~= '*' and string.sprintf(self.wrapper, value) or value;
end
--
--/**
--* Convert an array of column names into a delimited string.
--*
--* @param  array   $columns
--* @return string
--*/
function Grammar:columnize(columns)
--   ngx.say(columns)
   local callback = function(column)
      return self:wrap(column)
   end
   return array.implode(', ', array.map(callback,columns));
end
--
--/**
--* Create query parameter place-holders for an array.
--*
--* @param  array   $values
--* @return string
--*/
function Grammar:parameterize(values)
   local callback =function(value)
      return self:parameter(value)
   end
   return array.implode(', ', array.map(callback, values));
end
--
--/**
--* Get the appropriate query parameter place-holder for a value.
--*
--* @param  mixed   $value
--* @return string
--*/
function Grammar:parameter(value)
   return self:isExpression(value) and self:getValue(value) or '?'
end
--
--/**
--* Get the value of a raw expression.
--*
--* @param  \Illuminate\Database\Query\Expression  $expression
--* @return string
--*/
function Grammar:getValue(expression)
  return expression:getValue()
end
--
--/**
--* Determine if the given value is a raw expression.
--*
--* @param  mixed  $value
--* @return bool
--*/
function Grammar:isExpression(value)
  return instanceof(value,Expression)
end
--
--/**
--* Get the format for database stored dates.
--*
--* @return string
--*/
function Grammar:getDateFormat()
   return 'Y-m-d H:i:s';
end
--
--/**
--* Get the grammar's table prefix.
--*
--* @return string
--*/
function Grammar:getTablePrefix()
  return self.tablePrefix
end
--
--/**
--* Set the grammar's table prefix.
--*
--* @param  string  $prefix
--* @return \Illuminate\Database\Grammar
--*/
function Grammar:setTablePrefix(prefix)
   self.tablePrefix = prefix
   return self
end

return Grammar
