--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-10
-- Time: 下午9:40
-- To change this template use File | Settings | File Templates.
--


--<?php namespace Illuminate\Database\Schema;
--
--use Closure;
--use Illuminate\Support\Fluent;
--use Illuminate\Database\Connection;
--use Illuminate\Database\Schema\Grammars\Grammar;
--
local pairs = pairs
local error = error
local type = type
local string = require("application.library.string")
local array = require("application.library.array")
local Blueprint = {}
Blueprint.__index = Blueprint
--
--    /**
--            * The table the blueprint describes.
--*
--* @var string
--*/
Blueprint.table = nil
--
--/**
--* The columns that should be added to the table.
--*
--* @var array
--*/
Blueprint.columns = {}
--
--/**
--* The commands that should be run for the table.
--*
--* @var array
--*/
Blueprint.commands = {}
--
--/**
--* The storage engine that should be used for the table.
--*
--* @var string
--*/
Blueprint.engine = nil
--
--/**
--* Create a new schema blueprint.
--*
--* @param  string   $table
--* @param  Closure  $callback
--* @return void
function Blueprint.new(table,callback)

    local self = setmetatable({}, Blueprint)

    self.table = table

    if callback then
        callback(self)
    end

    return self
end
--
--/**
--* Execute the blueprint against the database.
--*
--* @param  \Illuminate\Database\Connection  $connection
--* @param  \Illuminate\Database\Schema\Grammars\Grammar $grammar
--* @return void
--*/
function Blueprint:build(connection, grammar)

    local statements = self:toSql(connection,grammar)

    for _, statement in pairs(statements) do

        connection:statement(statement)

    end
end
--
--/**
--* Get the raw SQL statements for the blueprint.
--*
--* @param  \Illuminate\Database\Connection  $connection
--* @param  \Illuminate\Database\Schema\Grammars\Grammar  $grammar
--* @return array
--*/
function Blueprint:toSql(connection,grammar)

    self:addImpliedCommands()

    local statements = {}

    --// Each type of commad has a corresponding compiler function on the schema
    --// grammar which is used to build the necessary SQL statements to build
    --// the blueprint element, so we'll just call that compilers function.

    for _,command in pairs(self.commands) do
        local method = 'compile'.. string.ucfirst(command.name)
        if grammar[method] then
            local sql = grammar[method](self,command,connection)
            if sql then
                if type(sql) == 'string' then
                    sql = {sql}
                end
                statements = array.merge(statements,sql)
            end
        end
    end
    return statements
end
--
--/**
--* Add the commands that are implied by the blueprint.
--*
--* @return void
--*/
function Blueprint:addImpliedCommands()
    if array.count(self.columns) > 0 and not self:creating() then
        array.unshift(self.commands,self:createCommand('add'))
    end
    self:addFluentIndexes()
end
--
--/**
--* Add the index commands fluently specified on columns.
--*
--* @return void
--*/
function Blueprint:addFluentIndexes()

    local indexs = {'primary','unique','index'}
    for _,column in pairs(self.columns) do

        for _, index in pairs(indexs) do
        --// If the index has been specified on the given column, but is simply
        --// equal to "true" (boolean), no name has been specified for this
        --// index, so we will simply call the index methods without one.
            if column[index] == true then
                self[index](column.name)
                break
            elseif column.index then
                --// If the index has been specified on the column and it is something
                --// other than boolean true, we will assume a name was provided on
                --// the index specification, and pass in the name to the method.
                self[index](column.name,column.index)
                break
            end
        end
    end

end
--
--/**
--* Determine if the blueprint has a create command.
--*
--* @return bool
--*/
function Blueprint:creating()

    for _,command in pairs(self.commands) do
        if command.name == 'create' then
            return true
        end
    end

    return false
end
--
--/**
--* Indicate that the table needs to be created.
--*
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:create()
    return self:addCommand('create')
end
--/**
--* Indicate that the table should be dropped.
--*
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:drop()
   return self:addCommand('drop')
end
--
--/**
--* Indicate that the table should be dropped if it exists.
--*
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropIfExists()
   return self:addCommand('dropIfExists')
end
--
--/**
--* Indicate that the given columns should be dropped.
--*
--* @param  string|array  $columns
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropColumn(columns)

    if  not array.is_array(columns) then
        error('bad args to blueprint:dropColumn ')
    end
    return sefl:addCommand('dropColumn', {columns=columns})
end
--
--/**
--* Indicate that the given columns should be renamed.
--*
--* @param  string  $from
--* @param  string  $to
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:renameColumn(from, to)

   return self:addCommand('renameColumn', {from=from,to=to})

end
--
--/**
--* Indicate that the given primary key should be dropped.
--*
--* @param  string|array  $index
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropPrimary(index)

   return self:dropIndexCommand('dropPrimary','primary',index)

end

--
--/**
--* Indicate that the given unique key should be dropped.
--*
--* @param  string|array  $index
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropUnique(index)

   return self:dropIndexCommand('dropUnique','unique',index)

end
--
--/**
--* Indicate that the given index should be dropped.
--*
--* @param  string|array  $index
--* @return \Illuminate\Support\Fluent
--*/

function Blueprint:dropIndex(index)

   return self:dropIndexCommand('dropIndex','index',index)

end

--
--/**
--* Indicate that the given foreign key should be dropped.
--*
--* @param  string  $index
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropForeign(index)

    return self:dropIndexCommand('dropForeign','foregin',index)

end
--
--/**
--* Indicate that the timestamp columns should be dropped.
--*
--* @return void
--*/

function Blueprint:dropTimestamps()

   self:dropColumn({'created_at','updated_at'})

end
--
--/**
--* Indicate that the soft delete column should be dropped.
--*
--* @return void
--*/
function Blueprint:dropSoftDeletes()

    self:dropColumn('deleted_at')

end
--
--/**
--* Rename the table to a given name.
--*
--* @param  string  $to
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:rename(to)
    return self:addCommand('rename',{to=to})
end
--
--/**
--* Specify the primary key(s) for the table.
--*
--* @param  string|array  $columns
--* @param  string  $name
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:primary(columns,name)
    return self:indexCommand('primary',columns,name)
end
--
--/**
--* Specify a unique index for the table.
--*
--* @param  string|array  $columns
--* @param  string  $name
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:unique(columns,name)
    return self:indexCommand('unique',columns,name)
end
--
--/**
--* Specify an index for the table.
--*
--* @param  string|array  $columns
--* @param  string  $name
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:index(columns,name)
    return self:indexCommand('index',columns,name)
end
--
--/**
--* Specify a foreign key for the table.
--*
--* @param  string|array  $columns
--* @param  string  $name
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:foreign(columns,name)
    return self:indexCommand('foregin',columns,name)
end
--
--/**
--* Create a new auto-incrementing integer column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:increments(column)
    return self:unsignedInteger(column,true)
end
--
--/**
--* Create a new auto-incrementing big integer column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:bigIncrements(column)
    return self:unsignedBigInteger(column,true)
end
--
--/**
--* Create a new char column on the table.
--*
--* @param  string  $column
--* @param  int  $length
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:char(column,length)
    length = length or 255
    return self:addColumn('char',column,{length=length})
end
--
--/**
--* Create a new string column on the table.
--*
--* @param  string  $column
--* @param  int  $length
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:string(column,length)
   return self:addColumn('string',column,{length=length})
end
--
--/**
--* Create a new text column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:text(column)
    return self:addColumn('text',column)
end
--
--/**
--* Create a new medium text column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:mediumText(column)
   return self:addColumn('mediumText',column)
end
--
--/**
--* Create a new long text column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:longText(column)
   return self:addColumn('longText',column)
end
--
--/**
--* Create a new integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @param  bool  $unsigned
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:integer(column,autoIncrement,unsigned)
    return self:addColumn('integer',column,{autoIncrement=autoIncrement,unsigned=unsigned})
end
--
--/**
--* Create a new big integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @param  bool  $unsigned
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:bigInteger(column,autoIncrement,unsigned)
    return self:addColumn('bigInteger',column,{autoIncrement=autoIncrement,unsigned=unsigned})
end
--
--/**
--* Create a new medium integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @param  bool  $unsigned
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:mediumInteger(column,autoIncrement,unsigned)
    return self:addColumn('mediumInteger',column,{autoIncrement=autoIncrement,unsigned=unsigned})
end
--/**
--* Create a new tiny integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @param  bool  $unsigned
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:tinyInteger(column,autoIncrement,unsigned)
    return self:addColumn('tinyInteger',column,{autoIncrement=autoIncrement,unsigned=unsigned})
end
--
--/**
--* Create a new small integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @param  bool  $unsigned
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:smallInteger(column,autoIncrement,unsigned)
    return self:addColumn('smallInteger',column,{autoIncrement=autoIncrement,unsigned=unsigned})
end
--
--/**
--* Create a new unsigned integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:unsignedInteger(column,autoIncrement)
    return self:integer(column,autoIncrement,true)
end
--
--/**
--* Create a new unsigned big integer column on the table.
--*
--* @param  string  $column
--* @param  bool  $autoIncrement
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:unsignedBigInteger(column,autoIncrement)

    autoIncrement = autoIncrement or false

    return self:bigInteger(column,autoIncrement,true)

end
--
--/**
--* Create a new float column on the table.
--*
--* @param  string  $column
--* @param  int     $total
--* @param  int     $places
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:float(column,total,places)
    total = total or 8
    places = places or 2
    return self:addColumn('float',column,{total=total,places=places})
end
--
--/**
--* Create a new double column on the table.
--*
--* @param  string   $column
--* @param  int|null	$total
--* @param  int|null $places
--* @return \Illuminate\Support\Fluent
--*
--*/
function Blueprint:double(column,total,places)
    return self:addColumn('double',column,{total=total,places = places})
end
--
--/**
--* Create a new decimal column on the table.
--*
--* @param  string  $column
--* @param  int     $total
--* @param  int     $places
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:decimal(column,total,places)
    return self:addColumn('decimal',column,{total=total,places = places})
end
--
--/**
--* Create a new boolean column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:boolean(column)
    return self:addColumn('boolean',column)
end
--
--/**
--* Create a new enum column on the table.
--*
--* @param  string  $column
--* @param  array   $allowed
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:enum(column,allowed)
    return self:addColumn('enum',column,{allowed=allowed})
end
--
--/**
--* Create a new date column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:date(column)
    return self:addColumn('date',column)
end
--
--/**
--* Create a new date-time column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dateTime(column)
    return self:addColumn('dateTime',column)
end
--
--/**
--* Create a new time column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:time(column)
    return self:addColumn('time',column)
end
--
--/**
--* Create a new timestamp column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:timestamp(column)
   return self:addColumn('timestamp',column)
end
--
--/**
--* Add nullable creation and update timestamps to the table.
--*
--* @return void
--*/
function Blueprint:nullableTimestamps()
    self:timestamp('created_at'):nullable()
    self:timestamp('updated_at'):nullable()
end
--
--/**
--* Add creation and update timestamps to the table.
--*
--* @return void
--*/
function Blueprint:timestamps()
    self:timestamp('created_at')
    self:timestamp('updated_at')
end
--
--/**
--* Add a "deleted at" timestamp for the table.
--*
--* @return void
--*/
function Blueprint:softDeletes()
    self:timestamp('deleted_at'):nullable()
end
--
--/**
--* Create a new binary column on the table.
--*
--* @param  string  $column
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:binary(column)
    return self:addColumn('binary',column)
end
--
--/**
--* Add the proper columns for a polymorphic table.
--*
--* @param  string  $name
--* @return void
--*/
function Blueprint:morphs(name)
    self:unsignedInteger(name .. '_id')
    self:string(name .. '_type')
end
--
--/**
--* Create a new drop index command on the blueprint.
--*
--* @param  string  $command
--* @param  string  $type
--* @param  string|array  $index
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:dropIndexCommand(command,type,index)
   local columns = {}
   --// If the given "index" is actually an array of columns, the developer means
   --// to drop an index merely by specifying the columns involved without the
   --// conventional name, so we will built the index name from the columns.
    if array.is_array(index) then
        columns = index
        index = self:createIndexName(type,columns)
    end
    return self:indexCommand(command,columns,index)
end

--
--/**
--* Add a new index command to the blueprint.
--*
--* @param  string        $type
--* @param  string|array  $columns
--* @param  string        $index
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:indexCommand(type,columns,index)

    --// If no name was specified for this index, we will create one using a basic
    --// convention of the table name, followed by the columns, followed by an
    --// index type, such as primary or index, which makes the index unique.
    if not index then
        index = self:createIndexName(type,columns)
    end

    return self:addCommand(type,{index=index,columns=columns})

end

--
--/**
--* Create a default index name for the table.
--*
--* @param  string  $type
--* @param  array   $columns
--* @return string
--*/
function Blueprint:createIndexName(type,columns)

    local index = string.strtolower(self.table..'_'..array.implode('_',columns)..'_'..type)

    return string.preg_replace('[%-%.]','_',index)
end

--
--/**
--* Add a new column to the blueprint.
--*
--* @param  string  $type
--* @param  string  $name
--* @param  array   $parameters
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:addColumn(type,name,parameters)

    local attributes = array.merge({type=type,name=name},parameters)

    local column = Fluent:new(attributes)

    self.columns[#self.columns+1] = column

    return column
end
--
--/**
--* Remove a column from the schema blueprint.
--*
--* @param  string  $name
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Blueprint:removeColumn(name)

    self.columns = array.values(array.filter(self.columns,function(c)

        return c['attributes']['name'] ~= name

    end))

    return self
end

--
--/**
--* Add a new command to the blueprint.
--*
--* @param  string  $name
--* @param  array  $parameters
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:addCommand(name,parameters)

    local command = self:createCommand(name,parameters)

    self.commands[#self.commands+1] = command

    return command

end

--
--/**
--* Create a new Fluent command.
--*
--* @param  string  $namel
--* @param  array   $parameters
--* @return \Illuminate\Support\Fluent
--*/
function Blueprint:createCommand(name,parameters)
--  todo  very important
    return Fluent:new(array.merge({name=name},parameters))

end
--
--/**
--* Get the table the blueprint describes.
--*
--* @return string
--*/
function Blueprint:getTable()
    return self:table
end
--
--/**
--* Get the columns that should be added.
--*
--* @return array
--*/
function Blueprint:getColumns()
    return self:columns
end
--
--/**
--* Get the commands on the blueprint.
--*
--* @return array
--*/
function Blueprint:getCommands()
    return self:commands
end
--}
