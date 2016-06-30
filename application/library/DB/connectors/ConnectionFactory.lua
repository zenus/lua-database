--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-3
-- Time: 上午5:57
-- To change this template use File | Settings | File Templates.
--
--

local array = require("DB.helper.array")
--local array = require("library.array")
local MysqlConnector = require("DB.connectors.MysqlConnector")
local MysqlConnection = require("DB.MysqlConnection")
local cjson = require("cjson")
local randomseed = math.randomseed
local error = error
local random = math.random
local time = ngx.time







local ConnectionFactory = {}

ConnectionFactory.__index = ConnectionFactory

function ConnectionFactory.new()
local self = setmetatable({}, ConnectionFactory)
return self
end




-- Establish a PDO connection based on the configuration.
--
-- @param  array   $config
-- @param  string  $name
-- @return \Database\Connection

function ConnectionFactory:make(config,name)

    local config = self:parseConfig(config,name)

    if config['read'] then
        return self:createReadWriteConnection(config)
    else
        return self:createSingleConnection(config)
    end
end



--
--/**
--* Create a single database connection instance.
--*
--* @param  array  $config
--* @return \Illuminate\Database\Connection
--*/

function ConnectionFactory:createSingleConnection(config)
   local pdo = self:createConnector(config):connect(config)
   return self:createConnection(config['driver'], pdo, config['database'], config['prefix'], config);
end


--
--/**
--* Create a single database connection instance.
--*
--* @param  array  $config
--* @return \Illuminate\Database\Connection
--*/

function ConnectionFactory:createReadWriteConnection(config)
    local connection = self:createSingleConnection(self:getWriteConfig(config))
    return connection:setReadPdo(self:createReadPdo(config))
end



--
--/**
--* Create a new PDO instance for reading.
--*
--* @param  array  $config
--* @return \PDO
--*/
function ConnectionFactory:createReadPdo(config)
    local readConfig = self:getReadConfig(config)
    return self:createConnector(readConfig):connect(readConfig)
end

--
--/**
--* Get the read configuration for a read / write connection.
--*
--* @param  array  $config
--* @return array
--*/

function ConnectionFactory:getReadConfig(config)
    local readConfig = self:getReadWriteConfig(config,'read')
    return self:mergeReadWriteConfig(config,readConfig)
end

--
--/**
--* Get the read configuration for a read / write connection.
--*
--* @param  array  $config
--* @return array
--*/

function ConnectionFactory:getWriteConfig(config)
   local writeConfig = self:getReadWriteConfig(config,'write')
    return self:mergeReadWriteConfig(config,writeConfig)
end

--
--/**
--* Get a read / write level configuration.
--*
--* @param  array  $config
--* @param  string  $type
--* @return array
--*/

function ConnectionFactory:getReadWriteConfig(config,type)

    if config[type][1] then
        randomseed(time())
        return config[type][random(1,#config[type])]
    else
      return config[type]
    end

end
--
--/**
--* Merge a configuration for a read / write connection.
--*
--* @param  array  $config
--* @param  array  $merge
--* @return array
--*/



function ConnectionFactory:mergeReadWriteConfig(config,merge)
    return array.except(array.merge(config,merge),{'read','write'});
end

--
--/**
--* Parse and prepare the database configuration.
--*
--* @param  array   $config
--* @param  string  $name
--* @return array
--*/
function ConnectionFactory:parseConfig(config,name)
    config = array.add(config,'prefix','')
    return array.add(config,'name',name)
end


--
--/**
--* Create a connector instance based on the configuration.
--*
--* @param  array  $config
--* @return \Illuminate\Database\Connectors\ConnectorInterface
--*
--* @throws \InvalidArgumentException
--*/


function ConnectionFactory:createConnector(config)
    if not config['driver'] then
        error('A driver must be specified')
    end

    if (config['driver'] == 'mysql') then
        return MysqlConnector.new();
    end
    error('Unsupported driver ' .. config['driver'] )
end



--/**
--* Create a new connection instance.
--*
--* @param  string  $driver
--* @param  PDO     $connection
--* @param  string  $database
--* @param  string  $prefix
--* @param  array   $config
--* @return \Illuminate\Database\Connection
--*/

function ConnectionFactory:createConnection(driver,connection,database,prefix,config)

    local prefix = prefix or ''

    if driver == 'mysql' then
        return MysqlConnection.new(connection,database,prefix,config)
    end

    error('Unsupported driver ' .. driver)
end

return ConnectionFactory
