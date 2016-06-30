--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-13
-- Time: 上午7:28
-- To change this template use File | Settings | File Templates.
--


local array = require("DB.helper.array")
local class = require("DB.helper.class")
local Collection = require("DB.helper.Collection")
local Expression = require("DB.Query.Expression")
local JoinClause = require("DB.Query.JoinClause")
local cjson = require("cjson")
local error = error
local pcall = pcall
local type = type
local max = math.max
local pairs = pairs
local string = require("DB.helper.string")
local pcall = pcall

local QueryBuilder = class.create('QueryBuilder')


function QueryBuilder:__construct(connection,grammar,processor)

    self.operators = {
        '=', '<', '>', '<=', '>=', '<>', '!=',
        'like', 'not like', 'between', 'ilike',
        '&', '|', '^', '<<', '>>',
    }

    --
    --/**
    --* The current query value bindings.
    --*
    --* @var array
    --*/
    self.bindings = nil
    --
    --/**
    --* An aggregate function and column to be run.
    --*
    --* @var array
    --*/
    self.aggregate = nil
    --
    --/**
    --* The columns that should be returned.
    --*
    --* @var array
    --*/
    self.columns = nil
    --
    --/**
    --* Indicates if the query returns distinct results.
    --*
    --* @var bool
    --*/
    self.distinct = false
    --
    --/**
    --* The table which the query is targeting.
    --*
    --* @var string
    --*/
    self.from = nil
    --
    --/**
    --* The table joins for the query.
    --*
    --* @var array
    --*/
    self.joins = nil
    --
    --/**
    --* The where constraints for the query.
    --*
    --* @var array
    --*/
    self.wheres = nil
    --
    --/**
    --* The groupings for the query.
    --*
    --* @var array
    --*/
    self.groups = nil
    --
    --/**
    --* The having constraints for the query.
    --*
    --* @var array
    --*/
    self.havings = nil
    --
    --/**
    --* The orderings for the query.
    --*
    --* @var array
    --*/
    self.orders = nil
    --
    --/**
    --* The maximum number of records to return.
    --*
    --        * @var int
    --*/
    --public $limit;
    self.limit = nil
    --
    --/**
    --* The number of records to skip.
    --*
    --* @var int
    --*/
    self.offset = nil
    --
    --/**
    --* The query union statements.
    --*
    --* @var array
    --*/
    self.unions = nil
    --
    --/**
    --* Indicates whether row locking is being used.
    --*
    --* @var string|bool
    --*/
    self.lock = nil
    --
    --/**
    --* The key that should be used when caching the query.
    --*
    --* @var string
    --*/
    --protected $cacheKey;
    --
    --/**
    --* The number of minutes to cache the query.
    --*
    --* @var int
    --*/
    --protected $cacheMinutes;
    --
    --/**
    --* The tags for the query cache.
    --*
    --* @var array
    --*/
    --protected $cacheTags;
    --
    --/**
    --* The cache driver to be used.
    --*
    --* @var string
    --*/
    --protected $cacheDriver;
    --
   self.grammar = grammar
   self.processor = processor
   self.connection = connection
end

--
--/**
--* Set the columns to be selected.
--*
--* @param  array  $columns
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:select(columns)

    local columns = columns or { '*' }


    if type(columns) ~= 'string' then
        columns = {columns}
    end

    self.columns = columns

    if not array.is_array(self.columns) then
        error('queryBuilder select method parameter error')
    end

    return self
end

--/**
--* Add a new "raw" select expression to the query.
--*
--* @param  string  $expression
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:selectRaw(expression)

    return self:select(Expression:new(expression))

end
--
--/**
--* Add a new select column to the query.
--*
--* @param  mixed  $column
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:addSelect(column)

    if not array.is_array(column) then
        error('QueryBuilder method addSelect parameter error')
    end

    self.columns = array.merge(self.columns,column)

    return self

end

--
--/**
--* Force the query to only return distinct results.
--*
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:distinct()

   self.distinct = true

    return self
end

--
--/**
--* Set the table which the query is targeting.
--*
--* @param  string  $table
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:from(table)

    self.from = table

    return self
end
--
--/**
--* Add a join clause to the query.
--*
--* @param  string  $table
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $two
--* @param  string  $type
--* @param  bool  $where
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:join(table,one,operator,two,_type,where)

    _type = _type or 'inner'

    where = where or false

    --// If the first "column" of the join is really a Closure instance the developer
    --// is trying to build a join with a complex "on" clause containing more than
    --// one condition, so we'll add the join and call a Closure with the query.

    if type(one) == 'function' then
        self.joins = self.joins or {}
        local index = #self.joins + 1
        self.joins[index] = JoinClause.new(self,_type,table)
        self.joins[index] = one(self.joins[index])
    else
        --// If the column is simply a string, we can assume the join simply has a basic
        --// "on" clause with a single condition. So we will just build the join with
        --// this simple join clauses attached to it. There is not a join callback.

        local join = JoinClause.new(self,_type,table)


        self.joins = self.joins or {}
        self.joins[#self.joins+1] = join:on(one,operator,two,'and',where)

    end

    return self
end

--
--/**
--* Add a "join where" clause to the query.
--*
--* @param  string  $table
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $two
--* @param  string  $type
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:joinWhere(table,one,operator,two,type)

     type = type or 'inner'

    return self:join(table,one,operator,two,type,true)

end
--
--/**
--* Add a left join to the query.
--*
--* @param  string  $table
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $second
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:leftJoin(table,first,operator,second)

   return self:join(table,first,operator,second,'left')

end

--/**
--* Add a "join where" clause to the query.
--*
--* @param  string  $table
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $two
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:leftJoinWhere(table,one,operator,two)

    return self:joinWhere(table,one,operator,two,'left')

end

--/**
--* Add a basic where clause to the query.
--*
--* @param  string  $column
--* @param  string  $operator
--* @param  mixed   $value
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*
--* @throws \InvalidArgumentException
--*/

function QueryBuilder:where(column,operator,value,boolean)

   if (not value) and (not boolean )  then

       value,operator = operator, '='

   elseif self:invalidOperatorAndValue(operator,value) then

       error("Value must be provided.")

   end

   boolean = boolean or 'and'
   --// If the columns is actually a Closure instance, we will assume the developer
   --// wants to begin a nested where statement which is wrapped in parenthesis.
   --// We'll add that Closure to the query then return back out immediately.
    if type(column) == 'function' then
        return self:whereNested(column,boolean)

    end
   --// If the given operator is not found in the list of valid operators we will
   --// assume that the developer is just short-cutting the '=' operators and
   --// we will set the operators to '=' and set the values appropriately.
    if not array.in_array(string.strtolower(operator),self.operators) then
       value,operator = operator,'='
    end
   --// If the value is a Closure, it means the developer is performing an entire
   --// sub-select within the query and we will need to compile the sub-select
   --// within the where clause to get the appropriate query record results.
    if  type(value) == 'function' then
        return self:whereSub(column,operator,value,boolean)
    end
   --// If the value is "null", we will just assume the developer wants to add a
   --// where null clause to the query. So, we will allow a short-cut here to
   --// that method for convenience so the developer doesn't have to check.
    if not value then
        return self:whereNull(column,boolean,operator ~= '=')
    end
   --// Now that we are working with just a simple query we can put the elements
   --// in our array and add the query binding to our array of bindings that
   --// will be bound to each SQL statements when it is finally executed.

    local compact = {type='Basic',column=column,operator=operator,value=value,boolean=boolean }
    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
    if not class.instanceof(value,'Expression') then
        self.bindings =  self.bindings or {}
        self.bindings[#self.bindings+1] = value
    end
    return self
end

--
--/**
--* Add an "or where" clause to the query.
--*
--* @param  string  $column
--* @param  string  $operator
--* @param  mixed   $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhere(column,operator,value)
    return self:where(column,operator,value,'or')
end
--
--/**
--* Determine if the given operator and value combination is legal.
--*
--* @param  string  $operator
--* @param  mixed  $value
--* @return bool
--*/
function QueryBuilder:invalidOperatorAndValue(operator,value)

    local isOperator = array.in_array(operator,self.operators)
    return (isOperator and (operator ~= '=') and (not value))
end

--
--/**
--* Add a raw where clause to the query.
--*
--* @param  string  $sql
--* @param  array   $bindings
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereRaw(sql, bindings, boolean)
   local type = 'raw'
   local bindings = bindings or {}
   local boolean = boolean or 'and'
   local compact = {type=type,sql=sql,boolean=boolean }
   self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
   self.bindings =  self.bindings or {}
    self.bindings = array.merge(self.bindings,bindings)
    return self
end
--
--/**
--* Add a raw or where clause to the query.
--*
--* @param  string  $sql
--* @param  array   $bindings
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereRaw(sql,bindings)

    bindings = bindings or {}
    return self.whereRaw(sql,bindings,'or')

end
--
--/**
--* Add a where between statement to the query.
--*
--* @param  string  $column
--* @param  array   $values
--* @param  string  $boolean
--* @param  bool  $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereBetween(column,values,boolean,_not)
   local type = 'Between'
   local boolean  = boolean or 'and'
   local _not  = _not or false
   local compact = {}
   compact['column'] = column
   compact['type'] = type
   compact['boolean'] = boolean
   compact['not'] = _not
   self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
   self.bindings =  self.bindings or {}
    self.bindings = array.merge(self.bindings,values)
    return self
end

--
--/**
--* Add an or where between statement to the query.
--*
--* @param  string  $column
--* @param  array   $values
--* @param  bool  $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereBetween(column,values,_not)
    _not = _not or false
   return self:whereBetween(column,values,'or')
end
--
--/**
--* Add a where not between statement to the query.
--*
--* @param  string  $column
--* @param  array   $values
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNotBetween(column,values,boolean)
    boolean = boolean or 'and'
    return self:whereBetween(column,values,boolean,true)
end
--
--/**
--* Add an or where not between statement to the query.
--*
--* @param  string  $column
--* @param  array   $values
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereNotBetween(column,values)
    return self:whereNotBetween(column,values,'or')
end
--
--/**
--* Add a nested where statement to the query.
--*
--* @param  \Closure $callback
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNested(callback,boolean)

    boolean = boolean or 'and'
    --// To handle nested queries we'll actually create a brand new query instance
    --// and pass it off to the Closure that we have. The Closure can simply do
    --// do whatever it wants to a query then we will store it for compiling.
--   local query = self:newQuery()
--    query:from(self.from)
--    pcall(callback,query)

    local query = callback(self:newQuery():from(self.from))

    return self:addNestedWhereQuery(query,boolean)
end
--
--/**
--* Add another query builder as a nested where to the query builder.
--*
--* @param  \Illuminate\Database\Query\Builder|static $query
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:addNestedWhereQuery(query,boolean)

   boolean = boolean or 'and'

   if array.count(query.wheres) then
       local type = 'Nested'
       local compact = {type=type,query=query,boolean=boolean }
       self.wheres = self.wheres or {}
       self.wheres[#self.wheres+1] = compact
       self:mergeBindings(query)
   end

   return self
end

--
--/**
--* Add a full sub-select to the query.
--*
--* @param  string   $column
--* @param  string   $operator
--* @param  \Closure $callback
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereSub(column,operator,callback,boolean)
    local type = 'Sub'
    local query = self:newQuery()
    --// Once we have the query instance we can simply execute it so it can add all
    --// of the sub-select's conditions to itself, and then we can cache it off
    --// in the array of where clauses for the "main" parent query instance.
    pcall(callback,query)

    local compact = {type=type,column=column,operator=operator,query=query,boolean=boolean}

    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact

    self:mergeBindings(query)

    return self
end
--
--/**
--* Add an exists clause to the query.
--*
--* @param  \Closure $callback
--* @param  string   $boolean
--* @param  bool     $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereExists(callback,boolean,_not)
    boolean = boolean or 'and'
    _not = _not or false
    local type = _not and 'NotExists' or 'Exists'
    local query = self:newQuery()

    --// Similar to the sub-select clause, we will create a new query instance so
    --// the developer may cleanly specify the entire exists query and we will
    --// compile the whole thing in the grammar and insert it into the SQL.
    pcall(callback,query)

   local compact = {type=type,query=query,boolean=boolean}

    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact

    self.mergeBindings(query)

    return self

end

--
--/**
--* Add an or exists clause to the query.
--*
--* @param  \Closure $callback
--* @param  bool     $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereExists(callback,_not)
    return self:whereExists(callback,'or',_not)
end
--
--/**
--* Add a where not exists clause to the query.
--*
--* @param  \Closure $callback
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNotExists(callback,boolean)
    boolean = boolean or 'and'
    return self:whereExists(callback,boolean,true)
end
--
--/**
--* Add a where not exists clause to the query.
--*
--* @param  \Closure  $callback
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereNotExists(callback)
    return self:orWhereExists(callback,true)
end
--
--/**
--* Add a "where in" clause to the query.
--*
--* @param  string  $column
--* @param  mixed   $values
--* @param  string  $boolean
--* @param  bool    $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereIn(column,values,boolean,_not)
    local _type = _not and 'NotIn' or 'In'
    local boolean = boolean or 'and'
    local _not = _not or false
    --// If the value of the where in clause is actually a Closure, we will assume that
    --// the developer is using a full sub-select for this "in" statement, and will
    --// execute those Closures, then we can re-construct the entire sub-selects.
    if type(values) == 'function' then
        return self:whereInSub(column,values,boolean,_not)
    end
    local compact = {type=_type,column=column,values=values,boolean=boolean }
    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
    self.bindings = self.bindings or {}
    self.bindings = array.merge(self.bindings,values)
    return self
end
--
--/**
--* Add an "or where in" clause to the query.
--*
--* @param  string  $column
--* @param  mixed   $values
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereIn(column,values)
    return self:whereIn(column,values,'or')
end
--
--/**
--* Add a "where not in" clause to the query.
--*
--* @param  string  $column
--* @param  mixed   $values
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNotIn(column,values,boolean)
    return self:whereIn(column,values,boolean,true)
end
--
--/**
--* Add an "or where not in" clause to the query.
--*
--* @param  string  $column
--* @param  mixed   $values
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereNotIn(column,values)
    return self:whereNotIn(column,values,'or')
end
--
--/**
--* Add a where in with a sub-select to the query.
--*
--* @param  string   $column
--* @param  \Closure $callback
--* @param  string   $boolean
--* @param  bool     $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereInSub(column,callback,boolean,_not)
   local type = _not and 'NotInSub' or 'InSub'
   --// To create the exists sub-select, we will actually create a query and call the
   --// provided callback with the query so the developer may set any of the query
   --// conditions they want for the in clause, then we'll put it in this array.
   local query = self:newQuery();
    pcall(callback,query)
    local compact = {type=type,column=column,query=query,boolean=boolean}
   self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
    self.mergeBindings(query)
    return self
end

--
--/**
--* Add a "where null" clause to the query.
--*
--* @param  string  $column
--* @param  string  $boolean
--* @param  bool    $not
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNull(column,boolean,_not)
    local type = _not and 'NotNull' or 'Null'
    local compact = {type=type,column=column,boolean=boolean}
    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
    return self
end
--
--/**
--* Add an "or where null" clause to the query.
--*
--* @param  string  $column
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereNull(column)
    return self:whereNull(column,'or')
end
--
--/**
--* Add a "where not null" clause to the query.
--*
--* @param  string  $column
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereNotNull(column,boolean)
    boolean  = boolean or 'and'
    return self:whereNull(column,boolean,true)
end
--
--/**
--* Add an "or where not null" clause to the query.
--*
--* @param  string  $column
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orWhereNotNull(column)
    return self:whereNotNull(column,'or')
end
--
--/**
--* Add a "where day" statement to the query.
--*
--* @param  string  $column
--* @param  string   $operator
--* @param  int   $value
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereDay(column,operator,value,boolean)
    return self:addDateBasedWhere('Day',column,operator,value,boolean)
end
--
--/**
--* Add a "where month" statement to the query.
--*
--* @param  string  $column
--* @param  string   $operator
--* @param  int   $value
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereMonth(column,operator,value,boolean)
    return self:addDateBasedWhere('Month',column,operator,value,boolean)
end
--
--/**
--* Add a "where year" statement to the query.
--*
--* @param  string  $column
--* @param  string   $operator
--* @param  int   $value
--* @param  string   $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:whereYear(column,operator,value,boolean)
    return self:addDateBasedWhere('Year',column,operator,value,boolean)
end
--
--/**
--* Add a date based (year, month, day) statement to the query.
--*
--* @param  string  $type
--* @param  string  $column
--* @param  string  $operator
--* @param  int  $value
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:addDateBasedWhere(type,column,operator,value,boolean)
    local compact = {column=column,type=type,boolean=boolean,operator=operator,value=value}
    self.wheres = self.wheres or {}
    self.wheres[#self.wheres+1] = compact
    self.bindings = self.bindings or {}
    self.bindings[#self.bindings+1] = value
    return self
end
--
--/**
--* Handles dynamic "where" clauses to the query.
--*
--* @param  string  $method
--* @param  string  $parameters
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:dynamicWhere(method,parameters)
    local finder = string.substr(method,6)
    local segments = string.preg_split('(And|Or)(?=[A-Z])',finder)
    --// The connector variable will determine which connector will be used for the
    --// query condition. We will change it as we come across new boolean values
    --// in the dynamic method strings, which could contain a number of these.
    local connector = 'and'

    local index = 0

    for _,segment in pairs(segments) do
        --// If the segment is not a boolean connector, we can assume it is a column's name
        --// and we will add it to the query as a new constraint as a where clause, then
        --// we can keep iterating through the dynamic method string's segments again.
        if segment ~= 'And' and segment ~= 'Or' then
            self:addDynamic(segment,connector,parameters,index)
            index = index + 1
            --// Otherwise, we will store the connector so we know how the next where clause we
            --// find in the query should be connected to the previous ones, meaning we will
            --// have the proper boolean connector to connect the next where clause found.
        else
            connector = segment
        end
    end

    return self

end
--
--/**
--* Add a single dynamic where clause statement to the query.
--*
--* @param  string  $segment
--* @param  string  $connector
--* @param  array   $parameters
--* @param  int     $index
--* @return void
--*/
function QueryBuilder:addDynamic(segment,connector,parameters,index)
    --// Once we have parsed out the columns and formatted the boolean operators we
    --// are ready to add it to this query as a where clause just like any other
    --// clause on the query. Then we'll increment the parameter index values.
    local bool = string.strtolower(connector)
    self:where(string.snake_case(segment),'=',parameters[index],bool)

end
--
--/**
--* Add a "group by" clause to the query.
--*
--* @param  dynamic  $columns
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:groupBy(...)
    local arg = {...}
    if type(self.groups) ~= 'table' then
        self.groups = {self.groups}
    end
    self.groups = array.merge(self.groups,arg)
    return self
end
--
--/**
--* Add a "having" clause to the query.
--*
--* @param  string  $column
--* @param  string  $operator
--* @param  string  $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:having(column,operator,value)
    local type = 'basic'
    local compact = {type=type,column=column,operator=operator,value=value}
    self.havings = self.havings or {}
    self.havings[#self.havings+1] = compact
    self.bindings = self.bindings or {}
    self.bindings[#self.bindings+1] = value
    return self
end
--
--/**
--* Add a raw having clause to the query.
--*
--* @param  string  $sql
--* @param  array   $bindings
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:havingRaw(sql,bindings,boolean)
    bindings = bindings or {}
    boolean = boolean or 'and'
    local type = 'raw'
    local compact = {type=type,sql=sql,boolean=boolean}
    self.havings = self.havings or {}
    self.havings[#self.havings+1] = compact
    self.bindings = self.bindings or {}
    self.bindings[#self.bindings+1] = array.merge(self.bindings,bindings)
    return self
end
--
--/**
--* Add a raw or having clause to the query.
--*
--* @param  string  $sql
--* @param  array   $bindings
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orHavingRaw(sql,bindings)
    bindings = bindings or {}
    return self:havingRaw(sql,bindings,'or')
end
--
--/**
--* Add an "order by" clause to the query.
--*
--* @param  string  $column
--* @param  string  $direction
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orderBy(column,direction)

    local direction = string.strtolower(direction) == 'asc' and 'asc' or 'desc'
    local compact = {column=column,direction=direction }
    self.orders = self.orders or {}
    self.orders[#self.orders+1] = compact
    return self
end
--
--/**
--* Add an "order by" clause for a timestamp to the query.
--*
--* @param  string  $column
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:latest(column)
    column = column or 'created_at'
    return self:orderBy(column,'desc')
end
--
--/**
--* Add an "order by" clause for a timestamp to the query.
--*
--* @param  string  $column
--* @return \Illuminate\Database\Query\Builder|static
--*/

function QueryBuilder:oldest(column)
    column = column or 'created_at'
    return self:orderBy(column,'asc')
end
--
--/**
--* Add a raw "order by" clause to the query.
--*
--* @param  string  $sql
--* @param  array  $bindings
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:orderByRaw(sql,bindings)
    bindings = bindings or {}
    local type = 'raw'
    local compact = {type=type,sql=sql}
    self.orders = self.orders or {}
    self.orders[#self.orders+1] = compact
    self.bindings = array.merge(self.bindings,bindings)
    return self
end
--
--/**
--* Set the "offset" value of the query.
--*
--* @param  int  $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:offset(value)
    self.offset = max(0,value)
    return  self
end
--
--/**
--* Alias to set the "offset" value of the query.
--*
--* @param  int  $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:skip(value)
    return self:offset(value)
end
--
--/**
--* Set the "limit" value of the query.
--*
--* @param  int  $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:limit(value)
    if value > 0 then
        self.limit = value
    end
    return self
end
--
--/**
--* Alias to set the "limit" value of the query.
--*
--* @param  int  $value
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:take(value)
    return self:limit(value)
end
--
--/**
--* Set the limit and offset for a given page.
--*
--* @param  int  $page
--* @param  int  $perPage
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:forPage(page,perPage)
    perPage = 15
    return self:skip(((page-1)*perPage)):take(perPage)
end
--
--/**
--* Add a union statement to the query.
--*
--* @param  \Illuminate\Database\Query\Builder|\Closure  $query
--* @param  bool $all
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:union(query,all)
    all = all or false
    if type(query) == 'function' then
        local q = query
        query = self:newQuery()
        pcall(q,query)
    end
    local compact = {query=query,all=all}
    self.unions = self.unions or {}
    self.unions[#self.unions+1] = compact
    return self:mergeBindings(query)
end
--
--/**
--* Add a union all statement to the query.
--*
--* @param  \Illuminate\Database\Query\Builder|\Closure  $query
--* @return \Illuminate\Database\Query\Builder|static
--*/
function QueryBuilder:unionAll(query)
    return self:union(query,true)
end
--
--/**
--* Lock the selected rows in the table.
--*
--* @param  bool  $update
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:lock(value)
    value = value or true
    self.lock = value
    return self
end
--
--/**
--* Lock the selected rows in the table for updating.
--*
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:lockForUpdate()
   return self:lock(true)
end
--/**
--* Share lock the selected rows in the table.
--*
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:shareLock()
    return self:lock(false)
end
--
--/**
--* Get the SQL representation of the query.
--*
--* @return string
--*/
function QueryBuilder:toSql()
    return self.grammar:compileSelect(self)
end
--
--
--
--
--/**
--* Execute a query for a single record by ID.
--*
--* @param  int    $id
--* @param  array  $columns
--* @return mixed|static
--*/
function QueryBuilder:find(id,columns)
    return self:where('id','=',id):first(columns)
end
--
--/**
--* Pluck a single column's value from the first result of a query.
--*
--* @param  string  $column
--* @return mixed
--*/
function QueryBuilder:pluck(column)
    local result = self:first({column})
    if type(result) ~= 'table' then
        result = {result}
    end
    return array.count(result) > 0 and result or nil
end
--
--/**
--* Execute the query and get the first result.
--*
--* @param  array   $columns
--* @return mixed|static
--*/
function QueryBuilder:first(columns)
    local columns = columns or {'*' }
    local results = self:take(1):get(columns)
    return array.count(results) > 0 and results[1] or nil
end
--
--/**
--* Execute the query as a "select" statement.
--*
--* @param  array  $columns
--* @return array|static[]
--*/
function QueryBuilder:get(columns)
    local columns = columns or {'*' }
    return self:getFresh(columns)
end
--
--/**
--* Execute the query as a fresh "select" statement.
--*
--* @param  array  $columns
--* @return array|static[]
--*/
function QueryBuilder:getFresh(columns)
   local columns =  columns or {'*'}
    self.columns = self.columns or columns
    return self.processor:processSelect(self,self:runSelect())
end
--
--/**
--* Run the query as a "select" statement against the connection.
--*
--* @return array
--*/
function QueryBuilder:runSelect()
    return self.connection:select(self:toSql(),self.bindings)
end
--
--
--
--/**
--* Chunk the results of the query.
--*
--* @param  int  $count
--* @param  callable  $callback
--* @return void
--*/
function QueryBuilder:chunk(count,callback)
    local page = 1
    local results = self:forPage(page,count):get()
    while (array.count(results) > 0) do
        --// On each chunk result set, we will pass them to the callback and then let the
        --// developer take care of everything within the callback, which allows us to
        --// keep the memory low for spinning through large result sets for working.
        pcall(callback,results)
        page = page + 1
        results = self:forPage(page,count):get()
    end
end
--
--/**
--* Get an array with the values of a given column.
--*
--* @param  string  $column
--* @param  string  $key
--* @return array
--*/
function QueryBuilder:lists(column,key)

    local columns = self:getListSelect(column,key)
    local col = columns[1]
--    ngx.say(columns[1])
    --// First we will just get all of the column values for the record result set
    --// then we can associate those values with the column if it was specified
    --// otherwise we can just give these values back without a specific key.
    local results = Collection.new(self:get(columns))
    local values = results:fetch(col):all()
    --// If a key was specified and we have results, we will go ahead and combine
    --// the values with the keys of all of the records so that the values can
    --// be accessed by the key of the rows instead of simply being numeric.
    if  key and (array.count(results) > 0) then
       local  keys = results:fetch(key):all()
        return array.combine(keys,values)
    end

    return values

end
--
--/**
--* Get the columns that should be used in a list array.
--*
--* @param  string  $column
--* @param  string  $key
--* @return array
--*/
function QueryBuilder:getListSelect(column,key)

    local select = {}
    if key then
        select[#select+1] = key
    end

    select[#select+1] = column
    --// If the selected column contains a "dot", we will remove it so that the list
    --// operation can run normally. Specifying the table is not needed, since we
    --// really want the names of the columns as it is in this resulting array.
--    ngx.say(select)
    local dot = string.strpos(select[1],'.')
    if dot then
        select[1] = string.substr(select[1],dot+1)
    end
    return select
end

--
--/**
--* Concatenate values of a given column as a string.
--*
--* @param  string  $column
--* @param  string  $glue
--* @return string
--*/
function QueryBuilder:implode(column,glue)
    if not glue then
        return array.implode(self:lists(column))
    end
    return array.implode(glue,self:lists(column))
end
--
--/**
--* Get a paginator for the "select" statement.
--*
--* @param  int    $perPage
--* @param  array  $columns
--* @return \Illuminate\Pagination\Paginator
--*/
function QueryBuilder:paginate(perPage,columns)
    local perPage = perPage or 15
    local columns = columns or {'*'}

    local paginator = self.connection:getPaginator()

    if self.groups then
        return self:groupedPaginate(paginator,perPage,columns)
    else
        return self:ungroupedPaginate(paginator,perPage,columns)
    end
end
--
--/**
--* Create a paginator for a grouped pagination statement.
--*
--* @param  \Illuminate\Pagination\Environment  $paginator
--* @param  int    $perPage
--* @param  array  $columns
--* @return \Illuminate\Pagination\Paginator
--*/
function QueryBuilder:groupedPaginate(paginator,perPage,columns)
    local  results = self:get(columns)
    return self:buildRawPaginator(paginator,results,perPage)
end
--
--/**
--* Build a paginator instance from a raw result array.
--*
--* @param  \Illuminate\Pagination\Environment  $paginator
--* @param  array  $results
--* @param  int    $perPage
--* @return \Illuminate\Pagination\Paginator
--*/
function QueryBuilder:buidRawPaginator(paginator,results,perPage)
    --// For queries which have a group by, we will actually retrieve the entire set
    --// of rows from the table and "slice" them via PHP. This is inefficient and
    --// the developer must be aware of this behavior; however, it's an option.
    local start =  (paginator:getCurrentPage() - 1) * perPage

    local sliced =  array.slice(results,start,perPage)

    return paginator:make(sliced,array.count(results),perPage)

end
--
--/**
--* Create a paginator for an un-grouped pagination statement.
--*
--* @param  \Illuminate\Pagination\Environment  $paginator
--* @param  int    $perPage
--* @param  array  $columns
--* @return \Illuminate\Pagination\Paginator
--*/
function QueryBuilder:ungroupedPaginate(paginator,perPage,columns)

  local total = self:getPaginationCount()
  --// Once we have the total number of records to be paginated, we can grab the
  --// current page and the result array. Then we are ready to create a brand
  --// new Paginator instances for the results which will create the links.
  local page = paginator:getCurrentPage(total)
  local results = self:forPage(page,perPage):get(columns)
   return paginator:make(results,total,perPage)
end
--
--/**
--* Get the count of the total records for pagination.
--*
--* @return int
--*/
function QueryBuilder:getPaginationCount()
    local orders = self.orders
    self.orders = nil
    local columns = self.columns

    --// Because some database engines may throw errors if we leave the ordering
    --// statements on the query, we will "back them up" and remove them from
    --// the query. Once we have the count we will put them back onto this.
    local total = self:count()

    self.orders = orders

    --// Once the query is run we need to put the old select columns back on the
    --// instance so that the select query will run properly. Otherwise, they
    --// will be cleared, then the query will fire with all of the columns.
    self.columns = columns

    return total
end
--
--/**
--* Determine if any rows exist for the current query.
--*
--* @return bool
--*/
function QueryBuilder:exists()
    return self:count() > 0
end
--
--/**
--* Retrieve the "count" result of the query.
--*
--* @param  string  $column
--* @return int
--*/
function QueryBuilder:count(column)
    local column = column or '*'
    return self:aggregate('count',{column})
end
--
--/**
--* Retrieve the minimum value of a given column.
--*
--* @param  string  $column
--* @return mixed
--*/
function QueryBuilder:min(column)
   return self:aggregate('min',{column})
end
--
--/**
--* Retrieve the maximum value of a given column.
--*
--* @param  string  $column
--* @return mixed
--*/
function QueryBuilder:max(column)
    return  self:aggregate('max',{column})
end
--
--/**
--* Retrieve the sum of the values of a given column.
--*
--* @param  string  $column
--* @return mixed
--*/
function QueryBuilder:sum(column)
   return self:aggregate('sum',{column})
end
--
--/**
--* Retrieve the average of the values of a given column.
--*
--* @param  string  $column
--* @return mixed
--*/
function QueryBuilder:avg(column)
    return self:aggregate('avg',{column})
end
--
--/**
--* Execute an aggregate function on the database.
--*
--* @param  string  $function
--* @param  array   $columns
--* @return mixed
--*/
function QueryBuilder:aggregate(_function,columns)
    local columns = columns or {'*' }
    local compact = {}
    compact['function'] =  _function
    compact['columns'] = columns
    self.aggregate = compact

    local results = self:get(columns)

    --// Once we have executed the query, we will reset the aggregate property so
    --// that more select queries can be executed against the database without
    --// the aggregate value getting in the way when the grammar builds it.
    self.columns = nil
    self.aggregate = nil

    if results[1] then
        local result = results[1]
        return result['aggregate']
    end
end
--
--/**
--* Insert a new record into the database.
--*
--* @param  array  $values
--* @return bool
--*/
function QueryBuilder:insert(values)

     local values = values
    --// Since every insert gets treated like a batch insert, we will make sure the
    --// bindings are structured in a way that is convenient for building these
    --// inserts statements by verifying the elements are actually an array.
    if not array.is_array(values) then
        values = {values }
     else
        --// Since every insert gets treated like a batch insert, we will make sure the
        --// bindings are structured in a way that is convenient for building these
        --// inserts statements by verifying the elements are actually an array.
--        ngx.say(cjson.encode(values))
        for key,value in pairs(values) do
            value = array.ksort(value)
            values[key] = value
        end
    end
    --// We'll treat every insert like a batch insert so we can easily insert each
    --// of the records into the database consistently. This will make it much
    --// easier on the grammars to just handle one type of record insertion.
    local bindings = {}


    for _,record in pairs(values) do
        bindings =  array.merge(bindings,array.values(record))
    end

    local sql = self.grammar:compileInsert(self,values)

    --// Once we have compiled the insert statement's SQL we can execute it on the
    --// connection and return a result as a boolean success indicator as that
    --// is the same type of result returned by the raw connection instance.
    bindings = self:cleanBindings(bindings)

    return self.connection:insert(sql,bindings)

end
--
--/**
--* Insert a new record and get the value of the primary key.
--*
--* @param  array   $values
--* @param  string  $sequence
--* @return int
--*/
function QueryBuilder:insertGetId(values,sequence)
    local vals = array.clone(values)
    local sql = self.grammar:compileInsertGetId(self,vals,sequence)
    local values = self:cleanBindings(values)
    local bindings = {}
    for _,record in pairs(values) do
        bindings =  array.merge(bindings,array.values(record))
    end
    return self.processor:processInsertGetId(self,sql,bindings,sequence)
end
--
--/**
--* Update a record in the database.
--*
--* @param  array  $values
--* @return int
--*/
function QueryBuilder:update(values)
   local bindings =  array.values(array.merge(values,self.bindings))
   local sql = self.grammar:compileUpdate(self,values)
    return self.connection:update(sql,self:cleanBindings(bindings))

end
--
--/**
--* Increment a column's value by a given amount.
--*
--* @param  string  $column
--* @param  int     $amount
--* @param  array   $extra
--* @return int
--*/
function QueryBuilder:increment(column,amount,extra)
    local m = {}
   local  amount = amount or 1
    local wrapped = self.grammar:wrap(column)
          m[column] = self:raw(wrapped .." + " .. amount)
    local columns = array.merge(m,extra)
    return self:update(columns)

end
--
--/**
--* Decrement a column's value by a given amount.
--*
--* @param  string  $column
--* @param  int     $amount
--* @param  array   $extra
--* @return int
--*/
function QueryBuilder:decrement(column,amount,extra)
    local amount = amount or 1
    local m = {}
    local wrapped = self.grammar:wrap(column)
     m[column] = self:raw(wrapped .." - " .. amount)
    local columns = array.merge(m,extra)
    return self:update(columns)
end
--
--/**
--* Delete a record from the database.
--*
--* @param  mixed  $id
--* @return int
--*/
function QueryBuilder:delete(id)
    --// If an ID is passed to the method, we will set the where clause to check
    --// the ID to allow developers to simply and quickly remove a single row
    --// from their database without manually specifying the where clauses.
    if id then
        self:where('id','=',id)
    end

    local sql = self.grammar:compileDelete(self)
    return self.connection:delete(sql,self.bindings)

end
--
--/**
--* Run a truncate statement on the table.
--*
--* @return void
--*/
function QueryBuilder:truncate()
    for sql,bindings in pairs(self.grammar:compileTruncate(self)) do
        self.connection:statement(sql,bindings)
    end
end
--
--/**
--* Get a new instance of the query builder.
--*
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:newQuery()
    return QueryBuilder:new(self.connection,self.grammar,self.processor)
end
--
--/**
--* Merge an array of where clauses and bindings.
--*
--* @param  array  $wheres
--* @param  array  $bindings
--* @return void
--*/
function QueryBuilder:mergeWheres(wheres,bindings)
    local wheres = wheres
    local bindings = bindings
    if type(self.wheres) ~= 'table' then
        self.wheres = {self.wheres}
    end
    if type(wheres) ~= 'table' then
        wheres = {wheres}
    end
    if type(bindings) ~= 'table' then
        bindings = {bindings}
    end
    self.wheres = array.merge(self.wheres,wheres)
    self.bindings = array.values(array.merge(self.bindings,bindings))
end
--
--/**
--* Remove all of the expressions from a list of bindings.
--*
--* @param  array  $bindings
--* @return array
--*/
function QueryBuilder:cleanBindings(bindings)
    return array.values(array.filter(bindings,function(binding)
        return not class.instanceof(binding,'Expression')
    end))
end
--
--/**
--* Create a raw database expression.
--*
--* @param  mixed  $value
--* @return \Illuminate\Database\Query\Expression
--*/
function QueryBuilder:raw(value)

   return self.connection:raw(value)

end

--
--/**
--* Get the current query value bindings.
--*
--* @return array
--*/
function QueryBuilder:getBindings()

    return self.bindings

end
--
--/**
--* Set the bindings on the query builder.
--*
--* @param  array  $bindings
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:setBindings(bindings)

    self.bindings = bindings

    return self
end
--
--/**
--* Add a binding to the query.
--*
--* @param  mixed  $value
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:addBinding(value)

    self.bindings = self.bindings or {}
    self.bindings[#self.bindings+1] = value

    return self
end

--
--/**
--* Merge an array of bindings into our bindings.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @return \Illuminate\Database\Query\Builder
--*/
function QueryBuilder:mergeBindings(query)

   self.bindings = array.values(array.merge(self.bindings,query.bindings))

    return self

end

--/**
--* Get the database connection instance.
--*
--* @return \Illuminate\Database\ConnectionInterface
--*/
function QueryBuilder:getConnection()
    return self.connection
end
--
--/**
--* Get the database query processor instance.
--*
--* @return \Illuminate\Database\Query\Processors\Processor
--*/
function QueryBuilder:getProcessor()
    return self.processor
end
--
--/**
--* Get the query grammar instance.
--*
--* @return \Illuminate\Database\Grammar
--*/
function QueryBuilder:getGrammar()
    return self.grammar
end


return QueryBuilder
--
--/**
--* Handle dynamic method calls into the method.
--*
--* @param  string  $method
--* @param  array   $parameters
--* @return mixed
--*
--* @throws \BadMethodCallException
--*/
--public function __call($method, $parameters)
--{
--if (starts_with($method, 'where'))
--{
--return $this->dynamicWhere($method, $parameters);
--}
--
--$className = get_class($this);
--
--throw new \BadMethodCallException("Call to undefined method {$className}::{$method}()");
--}
--
--}
