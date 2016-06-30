--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-4
-- Time: 下午8:22
-- To change this template use File | Settings | File Templates.
--
local Processor = require("DB.Query.Processors.Processor")
local Grammar = require("DB.Query.Grammars.Grammar")
local Builder = require("DB.Schema.Builder")
local QueryBuilder = require("DB.Query.QueryBuilder")
local Expression = require("DB.Query.Expression")
local class = require("library.class")
local array = require("library.array")
local cjson = require("cjson")

local error = error
local ngx = ngx
local ipairs = ipairs
local pairs = pairs
local type = type
local pcall = pcall
local floor = math.floor
local now = ngx.now
--local time = ngx.time
local gmatch = string.gmatch
local table_insert = table.insert

local Connection = class.create("Connection")

--
--/**
--* Create a new database connection instance.
--*
--* @param  Connect     $pdo
--* @param  string  $database
--* @param  string  $tablePrefix
--* @param  array   $config
--* @return void
function Connection:__construct(connect, database ,tablePrefix, config)
    --// First we will setup the default properties. We keep track of the DB
    --// name we are connected to since it is needed when some reflective
    --// type commands are run such as checking whether a table exists.
    self.connect = connect
    self.database = database or ''
    self.tablePrefix = tablePrefix or ''
    self.config = config or {}

    --
    --/**
    --* The active PDO connection used for reads.
    --*
    --* @var PDO
    --*/

    self.readConnect = nil
    --
    --/**
    --* The query grammar implementation.
    --*
    --* @var \Illuminate\Database\Query\Grammars\Grammar
    --*/
    self.queryGrammar = nil
    --
    --/**
    --* The schema grammar implementation.
    --*
    --* @var \Illuminate\Database\Schema\Grammars\Grammar
    --*/
    self.schemaGrammar = nil
    --
    --/**
    --* The query post processor implementation.
    --*
    --* @var \Illuminate\Database\Query\Processors\Processor
    --*/
    self.postProcessor = nil
    --
    --/**
    --* The event dispatcher instance.
    --*
    --* @var \Illuminate\Events\Dispatcher
    --*/
    self.events = nil
    --
    --/**
    --* The paginator environment instance.
    --*
    --* @var \Illuminate\Pagination\Paginator
    --*/
    self.paginator = nil
    --
    --/**
    --* The cache manager instance.
    --*
    --* @var \Illuminate\Cache\CacheManager
    --*/
    --  Connection.cache = nil
    --
    --/**
    --* The default fetch mode of the connection.
    --*
    --* @var int
    --*/
    --protected $fetchMode = PDO::FETCH_ASSOC;
    --
    --/**
    --* The number of active transasctions.
    --*
    --* @var int
    --*/
    self.transactions = 0
    --
    --/**
    --* All of the queries run against the connection.
    --*
    --* @var array
    --*/
    self.queryLog = {}
    --
    --/**
    --* Indicates whether queries are being logged.
    --*
    --* @var bool
    --*/
    self.loggingQueries = true
    --
    --/**
    --* Indicates if the connection is in a "dry run".
    --*
    --* @var bool
    --*/
    self.pretending = false
    --
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
function Connection:useDefaultQueryGrammar()

  self.queryGrammar = self:getDefaultQueryGrammar()

end
--
--/**
--* Get the default query grammar instance.
--*
--* @return \Illuminate\Database\Query\Grammars\Grammar
--*/
function Connection.getDefaultQueryGrammar()

    return Grammar:new()

end
--
--/**
--* Set the schema grammar to the default implementation.
--*
--* @return void
--*/
function Connection:useDefaultSchemaGrammar()

    self.schemaGrammar = self:getDefaultSchemaGrammar()

end
--
--/**
--* Get the default schema grammar instance.
--*
--* @return \Illuminate\Database\Schema\Grammars\Grammar
--*/
function Connection.getDefaultSchemaGrammar()

end

--
--/**
--* Set the query post processor to the default implementation.
--*
--* @return void
--*/
function Connection:useDefaultPostProcessor()

    self.postProcessor = self:getDefaultPostProcessor()

end
--
--/**
--* Get the default post processor instance.
--*
--* @return \Illuminate\Database\Query\Processors\Processor
--*/

function Connection.getDefaultPostProcessor()

    return Processor.new()

end

--
--/**
--* Get a schema builder instance for the connection.
--*
--* @return \Illuminate\Database\Schema\Builder
--*/

function Connection:getSchemaBuilder()
    if not self.schemaGrammar then
        self:useDefaultSchemaGrammar()
    end
    return Builder:new(self)
end
--
--/**
--* Begin a fluent query against a database table.
--*
--* @param  string  $table
--* @return \Illuminate\Database\Query\Builder
--*/
function Connection:table(table)
    local processor = self:getPostProcessor()
    local query = QueryBuilder.new(self,self:getQueryGrammar(),processor)
    return query:from(table)
end

--
--/**
--* Get a new raw query expression.
--*
--* @param  mixed  $value
--* @return \Illuminate\Database\Query\Expression
--*/
function Connection:raw(value)
    return Expression.new(value)
end
--
--/**
--* Run a select statement and return a single result.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return mixed
--*/
function Connection:selectOne(query,bindings)
    bindings = bindings or {}
    local records = self:select(query,bindings)
    return array.count(records) > 0 and records or nil
end

--/**
--* Execute the given callback in "dry run" mode.
--*
--* @param  Closure  $callback
--* @return array
--        */
function Connection:pretend(callback)
    self.pretending = true
    self.queryLog = {}
    --// Basically to make the database connection "pretend", we will just return
    --// the default values for all the query methods, then we will return an
    --// array of queries that were "executed" within the Closure callback.
    callback(self)
    self.pretending = false
    return self.queryLog
end

--/**
--* Get the current  connection used for reading.
--*
--* @return
--*/
function Connection:getReadConnect()
    if (self.transactions >=1) then
        return self:getConnect()
    end
--    return self.readConnect ? : self.connect
    return self.readConnect or self.connect
end


--/**
--* Prepare the query bindings for execution.
--*
--* @param  array  $bindings
--* @return array
--*/
function Connection:prepareBindings(bindings)

    --$grammar = $this->getQueryGrammar();
    --
    --foreach ($bindings as $key => $value)
    --{
    --// We need to transform all instances of the DateTime class into an actual
    --// date string. Each query grammar maintains its own date string format
    --// so we'll just ask the grammar for the format to get from the date.
    --if ($value instanceof DateTime)
    --{
    --$bindings[$key] = $value->format($grammar->getDateFormat());
    --}
    --elseif ($value === false)
    --{
    --$bindings[$key] = 0;
    --}
    --}
    --
    return bindings
end




--/**
--* Run a select statement against the database.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return array
--*/

function Connection:select(query, bindings)
    bindings = bindings or {}
    return self:run(query,bindings,function(me,query,bindings)
        if me:pretending() then
            return {}
        end
        --// For select statements, we'll simply execute the query and return an array
        --// of the database result set. Each element in the array will be a single
        --// row from the database table, and will either be an array or objects.
        local connect = me:getReadConnect()
        return connect:execute(query,me:prepareBindings(bindings))
    end)
end




--/**
--* Run an insert statement against the database.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return bool
--*/
function Connection:insert(query,bindings)
   return self:statement(query,bindings)
end

--
--/**
--* Run an update statement against the database.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return int
--*/
function Connection:update(query,bindings)
   return self:affectingStatement(query,bindings)
end


--
--/**
--* Run a delete statement against the database.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return int
--*/
function Connection:delete(query,bindings)
    return self:affectingStatement(query,bindings)
end

--/**
--* Execute an SQL statement and return the boolean result.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return bool
--*/
function Connection:statement(query,bindings)
    return self:run(query,bindings,function(me,query,bindings)
        if me:pretending() then
            return true
        end
        bindings = me:prepareBindings(bindings)
        return me:getConnect():execute(query,bindings)
    end)
end

--
--/**
--* Run an SQL statement and get the number of rows affected.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @return int
--*/
function Connection:affectingStatement(query,bindings)
    return self:run(query,bindings,function(me,query,bindings)
        if me:pretending() then
            return 0
        end
        --// For update or delete statements, we want to get the number of rows affected
        --// by the statement and return that back to the developer. We'll first need
        --// to execute the statement and then we'll use PDO to fetch the affected.
        local connect = me:getConnect()
        local res = connect:execute(query,me:prepareBindings(bindings))
        return res.affected_rows
    end)
end
--
--/**
--* Run a raw, unprepared query against the PDO connection.
--*
--* @param  string  $query
--* @return bool
--*/

function Connection:unprepared(query)
    return self:run(query,{},function(me,query)
        if me:pretending() then
            return true
        end
        return me:getConnect():execute(query)
    end)
end

--
--/**
--* Execute a Closure within a transaction.
--*
--* @param  Closure  $callback
--* @return mixed
--*
--* @throws \Exception
--*/
function Connection:transaction(callback)
    self:beginTransaction()
    --// We'll simply execute the given callback within a try / catch block
    --// and if we catch any exception we can rollback the transaction
    --// so that none of the changes are persisted to the database.
   local ret,err = pcall(callback,self)
   if not ret or err then
       self:rollBack()
--       todo throw error
       error(err)
   end
   self:commit()
   return ret
end

--
--/**
--* Start a new database transaction.
--*
--* @return void
--*/
function Connection:beginTransaction()
    self.transactions = self.transactions + 1
    if self.transactions == 1 then
        self.connect:beginTransaction()
    end
    self:fireConnectionEvent('beganTransaction')
end


--/**
--* Commit the active database transaction.
--*
--* @return void
--        */
function Connection:commit()
    if self.transactions ==1 then
        self.connect:commit()
    end
    self:fireConnectionEvent('committed')
end


--/**
--* Rollback the active database transaction.
--*
--* @return void
--*/
function Connection:rollBack()
    if self.transactions == 1 then
        self.transactions = 0
        self.connect:rollBack()
    else
        self.transactions = self.transactions - 1
    end
end

--/**
--* Run a SQL statement and log its execution context.
--*
--* @param  string   $query
--* @param  array    $bindings
--* @param  Closure  $callback
--* @return mixed
--*
--* @throws QueryException
--*/
function Connection:run(query,bindings,callback)
    local start = now()
-- // To execute the statement, we'll simply call the callback, which will actually
--// run the SQL against the PDO connection. Then we can calculate the time it
--// took to execute and log the query SQL, bindings and time in our memory.
    local status,result = pcall(callback,self,query,bindings)
          if not status then
              error(result)
          end
--    // Once we have run the query we will calculate the time that it took to run and
--    // then log the query, bindings, and execution time so we will report them on
--    // the event that the developer needs them. W	e'll log time in milliseconds.
    local time = self:getElapsedTime(start);

    self:logQuery(query, bindings, time);

    return result;

end


--
--/**
--* Log a query in the connection's query log.
--*
--* @param  string  $query
--* @param  array   $bindings
--* @param  $time
--* @return void
--*/
function Connection:logQuery(query,bindings,time)
   if self.events then
       self.events:fire('query',{query,bindings,time,self:getName()})
   end
   if not self.loggingQueries then
       return;
   end
   local log = {query=query,bindings=bindings,time=time}
   self.queryLog[#self.queryLog + 1] = log

end




--
--/**
--* Register a database query listener with the connection.
--*
--* @param  Closure  $callback
--* @return void
--*/
function Connection:listen(callback)
    if self.events then
        self.events:listen('query',callback)
    end
end
--
--/**
--* Get the elapsed time since a given starting point.
--*
--* @param  int    $start
--* @return float
--*/
function Connection:getElapsedTime(start)
    return floor(now()-start)
end
--
--/**
--* Get the current PDO connection.
--*
--* @return PDO
--*/
function Connection:getConnect()
    return self.connect
end
--
--/**
--* Get the current PDO connection used for reading.
--*
--* @return PDO
--*/
function Connection:getReadConnect()
    if self.transactions >= 1 then
        return self:getConnect()
    end
    return self.readConnect or self.connect
end
--
--/**
--* Set the PDO connection.
--*
--* @param  PDO  $pdo
--* @return \Illuminate\Database\Connection
--*/
function Connection:setConnect(connect)
    self.connect = connect
    return self
end
--
--/**
--* Set the PDO connection used for reading.
--*
--* @param  PDO  $pdo
--* @return \Illuminate\Database\Connection
--*/
function Connection:setReadConnect(connect)
    self.readConnect = connect
    return self
end
--
--/**
--* Get the database connection name.
--*
--* @return string|null
--*/
function Connection:getName()
    return self:getConfig('name')
end
--
--/**
--* Get an option from the configuration options.
--*
--* @param  string  $option
--* @return mixed
--*/
function Connection:getConfig(option)
    return self.config[option]
end
--
--/**
--* Get the PDO driver name.
--*
--* @return string
--*/
--public function getDriverName()
--{
--return $this->pdo->getAttribute(\PDO::ATTR_DRIVER_NAME);
--}
--
--/**
--* Get the query grammar used by the connection.
--*
--* @return \Illuminate\Database\Query\Grammars\Grammar
--*/
function Connection:getQueryGrammar()
    return self.queryGrammar
end
--
--/**
--* Set the query grammar used by the connection.
--*
--* @param  \Illuminate\Database\Query\Grammars\Grammar
--* @return void
--*/
function Connection:setQueryGrammar(grammar)
    self.queryGrammar = grammar
end
--
--/**
--* Get the schema grammar used by the connection.
--*
--* @return \Illuminate\Database\Query\Grammars\Grammar
--*/
function Connection:getSchemaGrammar()
    return self.schemaGrammar
end
--
--/**
--* Set the schema grammar used by the connection.
--*
--* @param  \Illuminate\Database\Schema\Grammars\Grammar
--* @return void
--*/
function Connection:setSchemaGrammar(grammar)
    self.schemaGrammar = grammar
end
--
--/**
--* Get the query post processor used by the connection.
--*
--* @return \Illuminate\Database\Query\Processors\Processor
--*/
function Connection:getPostProcessor()
    return self.postProcessor
end
--
--/**
--* Set the query post processor used by the connection.
--*
--* @param  \Illuminate\Database\Query\Processors\Processor
--* @return void
--*/
function Connection:setPostProcessor(processor)
    self.postProcessor = processor
end
--
--/**
--* Get the event dispatcher used by the connection.
--*
--* @return \Illuminate\Events\Dispatcher
--*/
function Connection:getEventDispatcher()
    return self.events
end
--
--/**
--* Set the event dispatcher instance on the connection.
--*
--* @param  \Illuminate\Events\Dispatcher
--* @return void
--*/
function Connection:setEventDispatcher(events)
    self.events = events
end
--
--/**
--* Get the paginator environment instance.
--*
--* @return \Illuminate\Pagination\Environment
--*/
function Connection:getPaginator()

    if type(self.paginator) == 'function' then

        self.paginator = self:paginator()

    end

    return self.paginator
end
--
--/**
--* Set the pagination environment instance.
--*
--* @param  \Illuminate\Pagination\Environment|\Closure  $paginator
--* @return void
--*/
function Connection:setPaginator(paginator)
   self.paginator = paginator
end
--
--
--/**
--* Determine if the connection in a "dry run".
--*
--* @return bool
--*/
function Connection:pretending()
    return self.pretending == true
end
--
--/**
--* Get the default fetch mode for the connection.
--*
--* @return int
--*/
function Connection:getFetchMode()
    return self.fetchMode
end
--
--/**
--* Set the default fetch mode for the connection.
--*
--* @param  int  $fetchMode
--* @return int
--*/
function Connection:setFetchMode(fetchMode)
   self.fetchMode = fetchMode
end
--/**
--* Get the connection query log.
--*
--* @return array
--*/
function Connection:getQueryLog()
    return self.queryLog
end
--
--/**
--* Clear the query log.
--*
--* @return void
--*/
function Connection:flushQueryLog()
    self.queryLog = {}
end
--
--/**
--* Enable the query log on the connection.
--*
--* @return void
--*/
function Connection:enableQueryLog()
    self.loggingQueries = true
end
--
--/**
--* Disable the query log on the connection.
--*
--* @return void
--*/
function Connection:disableQueryLog()
    self.loggingQueries = false
end

--/**
--* Determine whether we're logging queries.
--*
--* @return bool
--*/
function Connection:logging()
   return self.loggingQueries
end
--
--/**
--* Get the name of the connected database.
--*
--* @return string
--*/
function Connection:getDatabaseName()
    return self.database
end
--
--/**
--* Set the name of the connected database.
--*
--* @param  string  $database
--* @return string
--*/
function Connection:setDatabaseName(database)
    self.database = database
end
--
--/**
--* Get the table prefix for the connection.
--*
--* @return string
--*/
function Connection:getTablePrefix()
    return self.tablePrefix
end
--
--/**
--* Set the table prefix in use by the connection.
--*
--* @param  string  $prefix
--* @return void
--*/
function Connection:setTablePrefix(prefix)
    self.tablePrefix = prefix
    self:getQueryGrammar():setTablePrefix(prefix)
end
--
--/**
--* Set the table prefix and return the grammar.
--*
--* @param  \Illuminate\Database\Grammar  $grammar
--* @return \Illuminate\Database\Grammar
--*/
function Connection:withTablePrefix(grammar)
    grammar:setTablePrefix(self.tablePrefix)
    return grammar
end

return Connection
