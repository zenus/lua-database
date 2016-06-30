--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-4
-- Time: 下午5:18
-- To change this template use File | Settings | File Templates.
--

local Connector = require("DB.connectors.Connector")
local cjson = require("cjson")
local Mysql = require("resty.mysql")
local class = require("library.class")
local error = error
local ngx = ngx
local ipairs = ipairs
local pairs = pairs
local type = type
local gmatch = string.gmatch
local table_insert = table.insert

local MysqlConnector = class.create('MysqlConnector',Connector)


function MysqlConnector:__construct()
end

--function MysqlConnector:setDefaultConnection(connection)
--    self.connection = connection
--end

--/**
--* Establish a database connection.
--*
--* @param  array  $config
--* @return  connection
--*/

function MysqlConnector:connect(config)

    --// If the "strict" option has been configured for the connection we'll enable
    --// strict mode on all of these tables. This enforces some extra rules when
    --// using the MySQL database system and is a quicker way to enforce them.
    --if (isset($config['strict']) && $config['strict'])
    --{
    --$connection->prepare("set session sql_mode='STRICT_ALL_TABLES'")->execute();
    --}
    --
    local connection = self:createConnection(config)
    self.connection = connection

--    self:setDefaultConnection(connection)

    --// Next we will set the "names" and "collation" on the clients connections so
    --// a correct character set will be used by this client. The collation also
    --// is set on the server but needs to be set here on this client objects.

    local charset = config['charset']
    local names = 'set names ' .. charset


    if config['collation'] then
        names = names .. '  collate ' .. config['collation']
    end

    local res,err = connection:query(names)

    if not res then
        error("set charset error : ".. err)
    end

    --// If the "strict" option has been configured for the connection we'll enable
    --// strict mode on all of these tables. This enforces some extra rules when
    --// using the MySQL database system and is a quicker way to enforce them.
     if config['strict'] then
         local strict = "set session sql_mode='STRICT_ALL_TABLES'"
         local res,err = connection:query(strict)
         if not res then
             error("set session sql_mode error : ".. err)
         end
     end

--    local ok, err = db:set_keepalive(conf.pool_config.max_idle_timeout, conf.pool_config.pool_size)
--    if not ok then
--        --ngx.say("failed to set keepalive: ", err)
--        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
--    end
    return self

end

function MysqlConnector:createConnection(config)

    if not config.timeout then
        error("failed to config mysql connection time out")
    else
        self.timeout = config.timeout
    end
    if not config.max_idle_timeout then
        error("failed to config mysql pool max_idle_timeout ")
    else
        self.max_idle_timeout = config.max_idle_timeout
    end
    if not config.pool_size then
        error("failed to config  mysql pool_size ")
    else
        self.pool_size = config.pool_size
    end
    local connection, err = Mysql:new()
    if not connection then
        error("failed to instantiate mysql:" .. err)
    end
    connection:set_timeout(config.timeout) -- 1 sec
    local ok, err = connection:connect(config)
    if not ok then
        error("failed to connect:" .. err)
    end

    return connection
end



local function split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    local result = {}
    for match in gmatch((str .. delimiter),"(.-)"..delimiter) do
--   for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table_insert(result, match)
    end
    return result
end


local function compose(t, params)
    if t==nil or params==nil or type(t)~="table" or type(params)~="table" or #t~=#params+1 or #t==0 then
        return nil
    else
        local result = t[1]
        for i=1, #params do
            result = result .. params[i].. t[i+1]
        end
        return result
    end
end


local function table_is_array(t)
    --    ngx.say(t)
    if type(t) ~= "table" then
        return false
    end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

local function parse_sql(sql, params)
    if not params or not table_is_array(params) or #params == 0 then
        return sql
    end
    local new_params = {}
    for i, v in ipairs(params) do
        if v and type(v) == "string" then
            v = ngx.quote_sql_str(v)
        end
        table_insert(new_params, v)
    end
    local t = split(sql,"?")
    local sql = compose(t, new_params)
    return sql
end

function MysqlConnector:execute(query,bindings)
    bindings = bindings or {}
    local query = parse_sql(query,bindings)
    local res, err = self.connection:query(query)
    if not res or err then
        error(" execute query error: " .. err)
    end
    local ok, err = self.connection:set_keepalive(self.max_idle_timeout, self.pool_size)
    if not ok then
        --ngx.say("failed to set keepalive: ", err)
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    end
    return res
end


function MysqlConnector:beginTransaction()
  return self:execute("start transction")
end

function MysqlConnector:commit()
    return self:execute("commit")
end

function MysqlConnector:rollBack()
    return self:execute("rollback")
end


return MysqlConnector



