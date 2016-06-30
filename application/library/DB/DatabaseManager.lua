--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-2
-- Time: 上午6:54
-- To change this template use File | Settings | File Templates.
--

local app = require("config.application")
local cjson = require("cjson")
local pcall = pcall
local error = error
local DataManager = {} -- the table representing the class, which will double as the metatable for the instances

DataManager.__index = DataManager -- failed table lookups on the instances should fallback to the class table, to get methods

--/**
--* The database connection factory instance.
--*
--* @var \Illuminate\Database\Connectors\ConnectionFactory
--*/
--protected $factory;
--
--/**
--* The active connection instances.
--*
--* @var array
--*/
DataManager.connections = {}
--
--/**
--* The custom connection resolvers.
--*
--* @var array
--*/
DataManager.extensions = {}


-- Get a database connection instance.
-- @param  string  $name
-- @return Database\Connection

function DataManager:connection(name)

    name = name  or  self:getDefaultConnection()

-- If we haven't created this connection, we'll create it based on the config
-- provided in the application. Once we've created the connections we will
-- set the "fetch mode" for PDO which determines the query return types.
    if  not self.connections[name]  then
        local connection = self:makeConnection(name)
        self.connections[name] = self:prepare(connection)
    end
    return self.connections[name]

end


-- Reconnect to the given database.
-- @param  string  $name
-- @return \Database\Connection

function DataManager:reconnect(name)

 name = name or self:getDefaultConnection()

 self:disconnect(name)
 return self:connection(name)
 end




--
--/**
--* Disconnect from the given database.
--*
--* @param  string  $name
--* @return void
--*/

function DataManager:disconnect(name)
    name = name or self:getDefaultConnection()
    self.connections[name] = nil
end




--
-- Make the database connection instance.
--
-- @param  string  $name
-- @return \Database\Connection

function DataManager:makeConnection(name)

    local config = self:getConfig(name)
    --// First we will check by the connection name to see if an extension has been
    --// registered specifically for that connection. If it has we will call the
    --// Closure and pass it the config allowing it to resolve the connection.
    if self.extensions[name] then
     local  _,result =  pcall(self.extensions[name],config,name)
        return result
    end

    local driver = config['driver']
    --// Next we will check to see if an extension has been registered for a driver
    --// and will call the Closure if so, which allows us to have a more generic
    --// resolver for the drivers themselves which applies to all connections.
    if self.extensions[driver] then
      local   _,result =  pcall(self.extensions[driver],config,name)
        return result
    end
    return self.factory:make(config,name)
end




function DataManager:prepare(connection)

--    connection:setFetchMode(app['config']['database.fetch']);
    --$connection->setFetchMode($this->app['config']['database.fetch']);
    --
    --if ($this->app->bound('events'))
    --{
    --$connection->setEventDispatcher($this->app['events']);
    --}
    --
    --// The database connection can also utilize a cache manager instance when cache
    --// functionality is used on queries, which provides an expressive interface
    --// to caching both fluent queries and Eloquent queries that are executed.
    --$app = $this->app;
    --
--    connection:setCacheManager(function() return app['cache'] end);
    --
    --// We will setup a Closure to resolve the paginator instance on the connection
    --// since the Paginator isn't sued on every request and needs quite a few of
    --// our dependencies. It'll be more efficient to lazily resolve instances.
--    connection:setPaginator(function()  return app['paginator'] end);

    return connection;
end

-- Get the configuration for a connection.
--
-- @param  string  $name
-- @return array
--
-- @error \InvalidArgumentException

function DataManager:getConfig(name)

name = name or self:getDefaultConnection()

--// To get the database connection configuration, we will just pull each of the
--// connection configurations and get the configurations for the given name.
--// If the configuration doesn't exist, we'll throw an exception and bail.
local connections = app['database']['connections']

local config = connections[name]

if not config  then
    error('Database ' .. name ..' not configured.')
end

return config;

end



--
-- Get the default connection name.
--
-- @return string

function DataManager.getDefaultConnection()

    return app['database']['default']

end



--
-- Set the default connection name.
--
-- @param  string  $name
-- @return void

function DataManager.setDefaultConnection(name)
    app['database']['default'] = name
end


-- Register an extension connection resolver.
--
-- @param  string    $name
-- @param  callable  $resolver
-- @return void


function DataManager:extend(name,resolver)
   self.extensions[name] = resolver
end


--
-- Return all of the created connections.
--
-- @return array

function DataManager:getConnections()
    return self.connections;
end



function DataManager.new(ConnectionFactory)
    local old_index = DataManager.__index
    DataManager.__index = function (tb, key)
        local f = DataManager:connection()[key]
        if f then
--            return function(var1,var2,var3,var4)  return f(var1,var2,var3,var4) end
            return f;
        end
        return old_index[key]
    end
    DataManager.factory = ConnectionFactory
    local self = setmetatable({}, DataManager)
    return self
end



return DataManager

