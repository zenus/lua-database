----
---- Created by IntelliJ IDEA.
---- User: zenus
---- Date: 16-6-10
---- Time: 下午8:47
---- To change this template use File | Settings | File Templates.
----
--
local array = require("application.library.array")
local string = require("application.library.string")
local pcall = pcall
local Builder = {}

Builder.__index = Builder
--    /**
--            * The database connection instance.
--*
--* @var \Illuminate\Database\Connection
--*/
Builder.connection = nil
--
--/**
--* The schema grammar instance.
--*
--* @var \Illuminate\Database\Schema\Grammars\Grammar
--*/
Builder.grammar = nil
--
--/**
--* The Blueprint resolver callback.
--*
--* @var \Closure
--*/
Builder.resolver = nil
--
--/**
--* Create a new database Schema manager.
--*
--* @param  \Illuminate\Database\Connection  $connection
--* @return void

function Builder.new(connection)

    local self = setmetatable({}, Builder)

    self.connection = connection
    self.grammar = connection:getSchemaGrammar()

    return self
end

--
--/**
--* Determine if the given table exists.
--*
--* @param  string  $table
--* @return bool
--*/
function Builder:hasTable(table)

    local sql = self.grammar:compileTableExists()

    local table = self.connection:getTablePrefix() .. table

    return array.count(self.connection:select(sql,{table})) > 0
end

--
--/**
--* Determine if the given table has a given column.
--*
--* @param  string  $table
--* @param  string  $column
--* @return bool
--*/
function Builder:hasColumn(table,column)

   local column = string.strtolower(column)

    return array.in_array(column,array.map(string.strtolower,self:getColumnListing(table)))

end
--
--/**
--* Get the column listing for a given table.
--*
--* @param  string  $table
--* @return array
--*/
function Builder:getColumnListing(table)

    local table = self.connection:getTablePrefix() .. table

    local results = self.connection:select(self.grammar:compileColumnExists(table))

    return self.connection:getPostProcessor():processColumnListing(results)
end
--
--/**
--* Modify a table on the schema.
--*
--* @param  string   $table
--* @param  Closure  $callback
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:table(table,callback)
    self:build(self:createBlueprint(table,callback))
end
--
--/**
--* Create a new table on the schema.
--*
--* @param  string   $table
--* @param  Closure  $callback
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:create(table,callback)

   local blueprint = self:createBlueprint(table)

    blueprint:create()

    callback(blueprint)

    self:build(blueprint)
end

--
--/**
--* Drop a table from the schema.
--*
--* @param  string  $table
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:drop(table)

   local blueprint = self:createBlueprint(table)

    blueprint:drop()

    self:build(blueprint)
end

--
--/**
--* Drop a table from the schema if it exists.
--*
--* @param  string  $table
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:dropIfExists(table)

    local blueprint = self:createBlueprint(table)

    blueprint:dropIfExists()

    self:build(blueprint)
end

--
--/**
--* Rename a table on the schema.
--*
--* @param  string  $from
--* @param  string  $to
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:rename(from,to)

    local blueprint = self:createBlueprint(from)

    blueprint:rename(to)

    self:build(blueprint)

end
--
--/**
--* Execute the blueprint to build / modify the table.
--*
--* @param  \Illuminate\Database\Schema\Blueprint  $blueprint
--* @return void
--*/
function Builder:build(blueprint)

    blueprint:build(self.connection, self.grammar)

end
--
--/**
--* Create a new command set with a Closure.
--*
--* @param  string   $table
--* @param  Closure  $callback
--* @return \Illuminate\Database\Schema\Blueprint
--*/
function Builder:createBlueprint(table,callback)
    if self.resolver then
        local status, result = pcall(self.resolver, table, callback);
        return status and result
    else
        return Blueprint.new(table,callback)
    end

end
--
--/**
--* Get the database connection instance.
--*
--* @return \Illuminate\Database\Connection
--*/
function Builder:getConnection()
    return self.connection
end
--
--/**
--* Set the database connection instance.
--*
--* @param  \Illuminate\Database\Connection
--* @return \Illuminate\Database\Schema\Builder
--*/
function Builder:setConnection(connection)

    self.connection = connection

    return self
end
--
--/**
--* Set the Schema Blueprint resolver callback.
--*
--* @param  \Closure  $resolver
--* @return void
--*/
function Builder:blueprintResolver(resolver)

    self.resolver = resolver

end

return Builder

