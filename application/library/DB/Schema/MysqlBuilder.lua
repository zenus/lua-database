--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-13
-- Time: 上午7:00
-- To change this template use File | Settings | File Templates.
--

local array = require("library.array")
local Builder = require("DB.Schema.Builder")
local MysqlBuilder = {}

MysqlBuilder.__index = MysqlBuilder

setmetatable(MysqlBuilder, {
    __index = Builder -- this is what makes the inheritance work
})

function MysqlBuilder.new(connection)

    local self = setmetatable({}, MysqlBuilder)

    self.connection = connection
    self.grammar = connection:getSchemaGrammar()

    return self
end

--/**
--* Determine if the given table exists.
--*
--* @param  string  $table
--* @return bool
--        */
function MysqlBuilder:hasTable(table)

   local sql = self.grammar:compileTableExists()

    local database = self.grammar:compileTableExists()

    local table = self.connection:getTablePrefix()[table]

    return array.count(self.connection:select(sql,{database,table})) > 0
end

--
--/**
--* Get the column listing for a given table.
--*
--* @param  string  $table
--* @return array
--*/
function MysqlBuilder:getColumnListing(table)

   local sql = self.grammar:compileColumnExists()

   local database = self.connection:getDatabaseName()

    local table = self.connection:getTablePrefix()[table]

    local results = self.connection:select(sql,{database,table})

    return self.connection:getPostProcessor():processColumnListing(results)
end
