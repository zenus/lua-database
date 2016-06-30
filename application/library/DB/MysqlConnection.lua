--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-22
-- Time: 下午9:17
-- To change this template use File | Settings | File Templates.
--

local Connection = require("DB.Connection")
local MysqlBuilder = require("DB.Schema.MysqlBuilder")
local QueryGrammar = require("DB.Query.Grammars.MysqlGrammar")
local SchemaGrammar = require("DB.Schema.Grammars.MysqlGrammar")
local MysqlProcessor = require("DB.Query.Processors.MysqlProcessor")
local class = require("DB.helper.class")

local MysqlConnection = class.create("MysqlConnection",Connection)

--
--    /**
--            * Get a schema builder instance for the connection.
--*
--* @return \Illuminate\Database\Schema\MySqlBuilder
--*/
--/**
--* Create a new database connection instance.
--*
--* @param  Connect     $pdo
--* @param  string  $database
--* @param  string  $tablePrefix
--* @param  array   $config
--* @return void
function MysqlConnection:__construct(connect, database ,tablePrefix, config)



    self.connect = connect
    self.database = database or ''
    self.tablePrefix = tablePrefix or ''
    self.config = config or {}

    --// We need to initialize a query grammar and the query post processors
    --// which are both very important parts of the database abstractions
    --// so we initialize these to their default values while starting.

    self:useDefaultQueryGrammar()
    self:useDefaultPostProcessor()
end

--
--/**
--* Set the query grammar to the default implementation.
--*
--* @return void
--*/
function MysqlConnection:useDefaultQueryGrammar()

    self.queryGrammar = self:getDefaultQueryGrammar()

end

--
--/**
--* Set the query post processor to the default implementation.
--*
--* @return void
--*/
function MysqlConnection:useDefaultPostProcessor()

    self.postProcessor = self:getDefaultPostProcessor()

end


function MysqlConnection:getSchemaBuilder()

    if not self.schemaGrammar then
        self:useDefaultSchemaGrammar()
    end
    return MysqlBuilder.new(self)
end
--
--/**
--* Get the default query grammar instance.
--*
--* @return \Illuminate\Database\Query\Grammars\MySqlGrammar
--*/
function MysqlConnection:getDefaultQueryGrammar()
    return self:withTablePrefix(QueryGrammar.new())
end
--
--/**
--* Get the default schema grammar instance.
--*
--* @return \Illuminate\Database\Schema\Grammars\MySqlGrammar
--*/
function MysqlConnection:getDefaultSchemaGrammar()
    return self:withTablePrefix(SchemaGrammar.new())
end
--
--/**
--* Get the default post processor instance.
--*
--* @return \Illuminate\Database\Query\Processors\Processor
--*/
function MysqlConnection:getDefaultPostProcessor()
    return MysqlProcessor.new()
end
--
--/**
--* Get the Doctrine DBAL driver.
--*
--* @return \Doctrine\DBAL\Driver\PDOMySql\Driver
--*/
--protected function getDoctrineDriver()
--{
--return new DoctrineDriver;
--}
--
--}
return MysqlConnection
