--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-22
-- Time: 下午10:12
-- To change this template use File | Settings | File Templates.
--

--<?php namespace Illuminate\Database\Schema\Grammars;
--
--use Illuminate\Support\Fluent;
--use Illuminate\Database\Connection;
--use Illuminate\Database\Schema\Blueprint;
--
local array = require("application.library.array")
local Expression = require("DB.Query.Expression")
local Grammar = require("DB.Grammar")
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local type = type
local string = require("application.library.string")
local MysqlGrammar = {}
MysqlGrammar.__index = MysqlGrammar

setmetatable(MysqlGrammar, {
    __index = Grammar -- this is what makes the inheritance work
})
--
--    /**
--            * The keyword identifier wrapper format.
--*
--* @var string
--*/
MysqlGrammar.wrapper = '`%s`'
--
--/**
--* The possible column modifiers.
--*
--* @var array
--*/
MysqlGrammar.modifiers = {'Unsigned','Nullable','Default','Increment','After'}
--
--/**
--* The possible column serials
--*
--* @var array
--*/
MysqlGrammar.serials = {'bigInteger','integer','mediumInteger','smallInteger', 'tinyInteger' }


function MysqlGrammar.new()
    local self = setmetatable({}, MysqlGrammar)
    return self
end

--
--/**
--* Compile the query to determine the list of tables.
--*
--* @return string
--        */
function MysqlGrammar:compileTableExists()
    return 'select * from information_schema.tables where table_schema = ? and table_name = ?';
end
--
--/**
--* Compile the query to determine the list of columns.
--*
--* @param  string  $table
--* @return string
--*/
function MysqlGrammar:compileColumnExists()
    return "select column_name from information_schema.columns where table_schema = ? and table_name = ?";
end
--
--/**
--* Compile a create table command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @param  \Illuminate\Database\Connection  $connection
--* @return string
--*/
function MysqlGrammar:compileCreate(blueprint,command,connection)

    local columns = array.implode(',',self:getColumns(blueprint))
    local sql = 'create table' .. self:wrapTable(blueprint) .. " ("..columns..")"
    --// Once we have the primary SQL, we can add the encoding option to the SQL for
    --// the table.  Then, we can check if a storage engine has been supplied for
    --// the table. If so, we will add the engine declaration to the SQL query.
    sql = self:compileCreateEncoding(sql,connection)

    if blueprint.engine then
        sql = sql .. ' engine = '..blueprint.engine
    end
    return sql

end
--
--/**
--* Append the character set specifications to a command.
--*
--* @param  string  $sql
--* @param  \Illuminate\Database\Connection  $connection
--* @return string
--*/
function MysqlGrammar:compileCreateEndcoding(sql,connection)
    local charset = connection:getConfig('charset')
    if charset then
        sql = sql .. ' default character set' .. charset
    end
    local collation = connection:getConfig('collation')
    if collation then
        sql = sql .. ' collate '..collation
    end
    return sql
end
--
--/**
--* Compile a create table command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileAdd(blueprint,command)
   local table = self:wrapTable(blueprint)
   local columns = self:prefixArray('add',self:getColumns(blueprint))
   return 'alter table '..table..' '..array.implode(', ', columns);
end
--
--/**
--* Compile a primary key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compilePrimary(blueprint,command)
    command:name(nil)
    return self:compileKey(blueprint, command, 'primary key');
end
--
--/**
--* Compile a unique key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileUnique(blueprint,command)
    return self:compileKey(blueprint,command,'unique')
end
--
--/**
--* Compile a plain index key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileIndex(blueprint,command)
    return self:compileKey(blueprint,command,'index')
end
--
--/**
--* Compile an index creation command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @param  string  $type
--* @return string
--*/
function MysqlGrammar:compileKey(blueprint,command,type)

    local columns = self:columnize(command.columns)
    local table = self:wrapTable(blueprint)

    return "alter table "..table.." add "..type.." "..command.index(columns);

end
--
--/**
--* Compile a drop table command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDrop(blueprint,command)
    return 'drop table'..self:wrapTable(blueprint)
end
--
--/**
--* Compile a drop table (if exists) command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropIfExists(blueprint,command)
    return 'drop table if exists ' .. self:wrapTable(blueprint)
end
--
--/**
--* Compile a drop column command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropColumn(blueprint,command)

   local columns = self:prefixArray('drop',self:wrapArray(command.columns))

    local table = self:wrapTable(blueprint)

   return 'alter table '..table..' '..array.implode(', ', columns);
end
--
--/**
--* Compile a drop primary key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropPrimary(blueprint,command)
    return 'alter table '..self:wrapTable(blueprint)..' drop primary key';
end
--
--/**
--* Compile a drop unique key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropUnique(blueprint,command)
   local table = self:wrapTable(blueprint)
   return "alter table "..table.." drop index "..command.index;
end
--/**
--* Compile a drop index command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropIndex(blueprint,command)

   local table = self:wrapTable(blueprint)

   return "alter table "..table.." drop index "..command.index;

end
--
--/**
--* Compile a drop foreign key command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileDropForeign(blueprint,command)

  local  table = self:wrapTable(blueprint)

  return "alter table "..table.." drop foreign key "..command.index

end
--
--/**
--* Compile a rename table command.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $command
--* @return string
--*/
function MysqlGrammar:compileRename(blueprint,command)
   local from = self:wrapTable(blueprint)
    return "rename table " ..from.." to " .. self:wrapTable(command.to)
end
--
--/**
--* Create the column definition for a char type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeChar(column)
    return "char("..column.length..")";
end
--
--/**
--* Create the column definition for a string type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeString(column)
    return "varchar("..column.length..")";
end
--
--/**
--* Create the column definition for a text type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeText(column)
    return 'text'
end
--
--/**
--* Create the column definition for a medium text type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeMediumText(column)
    return 'mediumtext'
end
--
--/**
--* Create the column definition for a long text type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeLongText(column)
    return 'longtext'
end
--
--/**
--* Create the column definition for a big integer type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeBigInteger(column)
    return 'bigint'
end
--
--/**
--* Create the column definition for a integer type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeInteger(column)
    return 'int'
end
--
--/**
--* Create the column definition for a medium integer type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeMediumInteger(column)
    return 'mediumint'
end
--
--/**
--* Create the column definition for a tiny integer type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeTinyInteger(column)
    return 'tinyint'
end
--
--/**
--* Create the column definition for a small integer type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/

function MysqlGrammar:typeSmallInteger(column)
    return 'smallint'
end

--
--/**
--* Create the column definition for a float type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeFloat(column)
    return "float(" .. column.total ..", "..column.places")"
end
--
--/**
--* Create the column definition for a double type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeDouble(column)
    if column.total and column.places then
        return "double("..column.total..", "..column.places..")"
    else
        return 'double';
    end
end
--
--/**
--* Create the column definition for a decimal type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeDecimal(column)
   return "decimal(" ..column.total ..", "..column.places..")"
end
--
--/**
--* Create the column definition for a boolean type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeBoolean(column)
    return 'tinyint(1)'
end
--
--/**
--* Create the column definition for an enum type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeEnum(column)
    return "enum('" .. string.implode("', '",column.allowed) .. "')"
end
--
--/**
--* Create the column definition for a date type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeDate(column)
    return 'date'
end
--
--/**
--* Create the column definition for a date-time type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeDateTime(column)
   return 'datetime'
end

function MysqlGrammar:typeTime(column)
    return 'time'
end
--
--/**
--* Create the column definition for a timestamp type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeTimestamp(column)

   if not column.nullable then

       return 'timestamp default 0'

   end

   return 'timestamp'
end

--
--/**
--* Create the column definition for a binary type.
--*
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--*/
function MysqlGrammar:typeBinary(column)
    return 'blob'
end
--
--/**
--* Get the SQL for an unsigned column modifier.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string|null
--*/
function MysqlGrammar:modifyUnsigned(blueprint,column)
    if column.unsigned then
        return ' unsigned'
    end
end

--
--/**
--* Get the SQL for a nullable column modifier.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string|null
--*/
function MysqlGrammar:modifyNullable(blueprint,column)

    return column.nullable and ' null ' or ' not null'

end
--
--/**
--* Get the SQL for a default column modifier.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string|null
--*/
function MysqlGrammar:modifyDefault(blueprint,column)
    if not column.default then
        return ' default ' .. self:getDefaultValue(column.default)
    end
end
--
--/**
--* Get the SQL for an auto-increment column modifier.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string|null
--*/
function MysqlGrammar:modifyIncrement(blueprint,column)
   if array.in_array(column.type,self.serials) and column.autoIncrement then
       return ' auto_increment primary key'
   end
end
--
--/**
--* Get the SQL for an "after" column modifier.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string|null
--*/
function  MysqlGrammar:modifyAfter(blueprint,column)
    if column.after then
        return ' after ' .. self:wrap(column.after)
    end
end

--/**
--* Add the column modifiers to the definition.
--*
--* @param  string  $sql
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @param  \Illuminate\Support\Fluent  $column
--* @return string
--        */
function MysqlGrammar:addModifiers(sql,blueprint,column)
    for _,modifier in pairs(self.modifiers) do
        local method = "modify"..modifier
        if self[method] then
            sql = sql .. self[method](blueprint,column)
        end
    end
    return sql
end

--/**
--* Compile the blueprint's column definitions.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @return array
--        */
function MysqlGrammar:getColumns(blueprint)
    local columns = {}
    for _,column in pairs(blueprint:getColumns()) do
        --// Each of the column types have their own compiler functions which are tasked
        --// with turning the column definition into its SQL format for this platform
        --// used by the connection. The column's modifiers are compiled and added.
        local sql = self:wrap(column) ..' '..self:getType(column)
        columns[#columns+1] = self:addModifiers(sql,blueprint,column)
    end
    return columns
end

--/**
--* Add a prefix to an array of values.
--*
--* @param  string  $prefix
--* @param  array   $values
--* @return array
--        */
  function MysqlGrammar:prefixArray(prefix,values)
     return array.map(function(value)
         return prefix .. ' '..value
     end,values)
  end

--/**
--* Format a value so that it can be used in "default" clauses.
--*
--* @param  mixed   $value
--* @return string
--        */
function MysqlGrammar:getDefaultValue(value)
    if instance(value,Expression) then
       return value
    end

    if type(value) == 'boolean' then
        return "'"..tonumber(value).."'"
    end

    return "'"..tostring(value).."'"

end

return MysqlGrammar
