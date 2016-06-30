--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-9
-- Time: 上午10:34
-- To change this template use File | Settings | File Templates.
--
local BaseGrammar = require("DB.Query.Grammars.BaseGrammar")
local cjson = require("cjson")
local array = require("library.array")
--local tostring = tostring
local string = require("library.string")
local class = require("library.class")
local pairs = pairs
local type = type
local rawget = rawget

local Grammar = class.create('Grammar',BaseGrammar)


--/**
--* The keyword identifier wrapper format.
--*
--* @var string
--*/
function Grammar:__construct()
   self.wrapper = '"%s"'
   self.selectComponents = {
       'aggregate',
       'columns',
       'from',
       'joins',
       'wheres',
       'groups',
       'havings',
       'orders',
       'limit',
       'offset',
       'unions',
       'lock',
   }
end

--
--/**
--* Compile a select query into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder
--* @return string
--        */
function Grammar:compileSelect(query)
            if not query.columns then
            query.columns = {'*'}
        end
         return string.trim(self:concatenate(self:compileComponents(query)))
end
--
--/**
--* Compile the components necessary for a select clause.
--*
--* @param  \Illuminate\Database\Query\Builder
--* @return array
--*/
function Grammar:compileComponents(query)
       local sql = {}
       for _,v in pairs(self.selectComponents) do
           --// To compile the query, we'll spin through each component of the query and
           --// see if that component exists. If it does we'll just call the compiler
           --// function for the component which is responsible for making the SQL.
           if rawget(query,v) then
               local method = 'compile' .. string.ucfirst(v)
               sql[#sql+1] = self[method](self,query,query[v])
           end
       end
       return sql
end

--
--/**
--* Compile an aggregated select clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $aggregate
--* @return string
--*/
function Grammar:compileAggregate(query,aggregate)

    local column = self:columnize(aggregate['columns'])
    --// If the query has a "distinct" constraint and we're not asking for all columns
    --// we need to prepend "distinct" onto the column name so that the query takes
    --// it into account when it performs the aggregating operations on the data.
    if query.distinct and column ~= '*' then
        column = 'distinct' .. column
    end

    return  'select ' .. aggregate['function'] ..'(' .. column .. ') as aggregate'

end

--
--/**
--* Compile the "select *" portion of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $columns
--* @return string
--*/
function Grammar:compileColumns(query,columns)

    --// If the query is actually performing an aggregating select, we will let that
    --// compiler handle the building of the select clauses, as it will need some
    --// more syntax that is best handled by that function to keep things neat.
    if  query.aggregate and type(query.aggregate) == 'table' then
        return
    end

    local select = query.distinct  and  'select distinct ' or 'select '

    return select .. self:columnize(columns)
end

--
--/**
--* Compile the "from" portion of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  string  $table
--* @return string
--*/
function Grammar:compileFrom(query,table)

   return 'from ' .. self:wrapTable(table)

end

--
--/**
--* Compile the "join" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $joins
--* @return string
--*/
function Grammar:compileJoins(query,joins)
    local sql = {}
    for _, join in pairs(joins) do
        local table = self:wrapTable(join.table)
        --// First we need to build all of the "on" clauses for the join. There may be many
        --// of these clauses so we will need to iterate through each one and build them
        --// separately, then we'll join them up into a single string when we're done.
        local clauses = {}
        for _,clause in pairs(join.clauses) do
            clauses[#clauses+1] = self:compileJoinConstraint(clause)
        end
        --// Once we have constructed the clauses, we'll need to take the boolean connector
        --// off of the first clause as it obviously will not be required on that clause
        --// because it leads the rest of the clauses, thus not requiring any boolean.
        clauses[1] = self:removeLeadingBoolean(clauses[1])
        clauses = array.implode(' ', clauses)
        local type = join.type
        --// Once we have everything ready to go, we will just concatenate all the parts to
        --// build the final join statement SQL for the query and we can then return the
        --// final clause back to the callers as a single, stringified join statement.
        sql[#sql+1] = type .." join " .. table .." on " .. clauses
    end

    return array.implode(' ',sql)
end
--
--/**
--* Create a join clause constraint segment.
--*
--* @param  array   $clause
--* @return string
--*/
--    'compileJoinConstraint
function Grammar:compileJoinConstraint(clause)

    local first = self:wrap(clause['first'])

    local second =  clause['where'] and '?' or self:wrap(clause['second'])

    return clause['boolean'] .. " " .. first .." ".. clause['operator'] .. " " .. second

end

--
--/**
--* Compile the "where" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @return string
--*/
function Grammar:compileWheres(query)
    local sql = {}
    if not query.wheres then return '' end
    --// Each type of where clauses has its own compiler function which is responsible
    --// for actually creating the where clauses SQL. This helps keep the code nice
    --// and maintainable since each clause has a very small method that it uses.
    for _,where in pairs(query.wheres) do
        local method = "where" .. where['type']
         sql[#sql+1] = where['boolean'] .. ' '.. self[method](self,query,where)
    end
    --// If we actually have some where clauses, we will strip off the first boolean
    --// operator, which is added by the query builders for convenience so we can
    --// avoid checking for the first clauses in each of the compilers methods.
    if array.count(sql) > 0 then
        sql  = array.implode(' ',sql)
        return 'where ' .. string.preg_replace('and |or ','',sql,1)
    end
    return '';
end
--
--/**
--* Compile a nested where clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/

function Grammar:whereNested(query,where)

    local nested = where['query']
    return '(' .. string.substr(self:compileWheres(nested), 7)  .. ')';

end

--
--/**
--* Compile a where condition with a sub-select.
--*
--* @param  \Illuminate\Database\Query\Builder $query
--* @param  array   $where
--* @return string
--*/
function Grammar:whereSub(query,where)

    local select = self:compileSelect(where['query'])

    return self:wrap(where['column']) .. ' ' .. where['operator'] .. " (" .. select ..")"
end
--
--/**
--* Compile a basic where clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereBasic(query,where)

    local value = self:parameter(where['value'])

    return  self:wrap(where['column']) .. ' ' .. where['operator'] .. ' ' .. value
end
--
--/**
--* Compile a "between" where clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereBetween(query,where)

    local between = where['not'] and 'not between' or 'between'

    return self:wrap(where['column']) .. ' ' .. between .. ' ? and ?'
end

--
--
--/**
--* Compile a where exists clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereExists(query, where)
   return 'exists ('..self:compileSelect(where['query'])..')';
end
--
--/**
--* Compile a where exists clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereNotExists(query,where)
    return 'not exists ('..self:compileSelect(where['query'])..')';
end
--
--/**
--* Compile a "where in" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereIn(query,where)
   local values = self:parameterize(where['values'])
    return self:wrap(where['column']) .. ' in (' .. values .. ')'
end
--/**
--* Compile a "where not in" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereNotIn(query,where)

    local values = self:parameterize(where['values'])

    return self:wrap(where['column']) .. ' not in (' .. values ..')'
end
--
--/**
--* Compile a where in sub-select clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/

function Grammar:whereInSub(query, where)
    local select = self:compileSelect(where['query'])
    return self:wrap(where['column']) .. ' in ('.. select ..')'
end
--
--/**
--* Compile a where not in sub-select clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereNotInSub(query,where)
    local select = self:compileSelect(where['query'])
    return self:wrap(where['column']) .. ' not in ('.. select ..')'
end
--
--/**
--* Compile a "where null" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereNull(query,where)
    return self:wrap(where['column']) .. ' is null'
end
--
--/**
--* Compile a "where not null" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereNotNull(query,where)
    return self:wrap(where['column']) .. 'is not null'
end
--
--/**
--* Compile a "where day" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereDay(query,where)
    return self:dataBasedWhere('day', query, where)
end
--
--/**
--* Compile a "where month" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/

function Grammar:whereMonth(query,where)
    return self:dataBasedWhere('month', query,where)
end
--
--/**
--* Compile a "where year" clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereYear(query,where)
    return self:dataBasedWhere('year',query,where)
end
--/**
--* Compile a date based where clause.
--*
--* @param  string  $type
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:dataBaseWhere(type,query,where)

    local value = self:parameter(where['value'])

    return type ..'(' ..self:wrap(where['column']) ..') '..where['operator'] ..' ' .. value
end
--
--/**
--* Compile a raw where clause.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $where
--* @return string
--*/
function Grammar:whereRaw(query,where)
    return where['sql']
end
--
--/**
--* Compile the "group by" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $groups
--* @return string
--*/
function Grammar:compileGroups(query,groups)
    return 'group by ' .. self:columnize(groups);
end
--
--/**
--* Compile the "having" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $havings
--* @return string
--*/
function Grammar:compileHavings(query,havings)
    local callback = function(having)
        return self:compileHaving(having)
    end
    local sql = array.implode(' ', array.map(callback, havings))
    return 'having ' .. string.preg_replace('and ','',sql,1)
end
--
--/**
--* Compile a single having clause.
--*
--* @param  array   $having
--* @return string
--*/
function Grammar:compileHaving(having)
    --// If the having clause is "raw", we can just return the clause straight away
    --// without doing any more processing on it. Otherwise, we will compile the
    --// clause into SQL based on the components that make it up from builder.
    if having['type'] == 'raw' then
        return having['boolean'] .. ' ' .. having['sql']
    end
    return self:compileBasicHaving(having)
end
--
--/**
--* Compile a basic having clause.
--*
--* @param  array   $having
--* @return string
--*/
function Grammar:compileBasicHaving(having)

    local column = self:wrap(having['column'])

    local parameter = self:parameter(having['value'])

    return 'and '.. column .. ' '..having['operator'] .. ' ' .. parameter
end
--
--/**
--* Compile the "order by" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $orders
--* @return string
--*/
function Grammar:compileOrders(query,orders)
    local me = self
    return 'order by ' .. array.implode(', ', array.map(function(order)
        if order['sql'] then
            return order['sql']
        end
        return me:wrap(order['column']) .. ' ' .. order['direction']
    end,orders))
end
--
--/**
--* Compile the "limit" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  int  $limit
--* @return string
--*/
function Grammar:compileLimit(query,limit)
    return 'limit ' .. limit
end

--
--/**
--* Compile the "offset" portions of the query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  int  $offset
--* @return string
--*/
function Grammar:compileOffset(query,offset)
    return 'offset ' .. offset
end
--
--/**
--* Compile the "union" queries attached to the main query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @return string
--*/
function Grammar:compileUnions(query)
    local con = {}
    for _,union in pairs(query.unions) do
        con[#con+1] = self:compileUnion(union)
    end
    return string.ltrim(array.implode('',con))
end
--
--/**
--* Compile a single union statement.
--*
--* @param  array  $union
--* @return string
--*/
function Grammar:compileUnion(union)
    local joiner = union['all']  and ' union all ' or ' union '
    return joiner .. union['query']:toSql()
end

--
--/**
--* Compile an insert statement into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $values
--* @return string
--*/
function Grammar:compileInsert(query,values)
    --// Essentially we will force every insert to be treated as a batch insert which
    --// simply makes creating the SQL easier for us since we can utilize the same
    --// basic routine regardless of an amount of records given to us to insert.
    local table = self:wrapTable(query.from)
    if not array.is_array(array.reset(values)) then
       local  values = {values}
    end
    local columns = self:columnize(array.keys(array.reset(values)))
    --// We need to build a list of parameter place-holders of values that are bound
    --// to the query. Each insert should have the exact same amount of parameter
    --// bindings so we can just go off the first list of values in this array.
    local parameters = self:parameterize(array.reset(values))
    local value = array.fill(0,array.count(values),"("..parameters..")")
    parameters = array.implode(', ',value)
    return "insert into".. table .. "(" .. columns .. ") values" .. parameters

end
--
--/**
--* Compile an insert and get ID statement into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array   $values
--* @param  string  $sequence
--* @return string
--*/
function Grammar:compileInsertGetId(query,values,sequence)
   return self:compileInsert(query,values)
end
--
--/**
--* Compile an update statement into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $values
--* @return string
--*/
function Grammar:compileUpdate(query,values)

    local table = self:wrapTable(query.from)
    --// Each one of the columns in the update statements needs to be wrapped in the
    --// keyword identifiers, also a place-holder needs to be created for each of
    --// the values in the list of bindings so we can make the sets statements.
    local columns = {}
    for key,value in pairs(values) do
        columns[#columns+1] = self:wrap(key) .. ' = ' .. self:parameter(value)
    end
    local columns = array.implode(', ',columns)
    --// If the query has any "join" clauses, we will setup the joins on the builder
    --// and compile them so we can attach them to this update, as update queries
    --// can get join statements to attach to other tables when they're needed.

    local joins = ''
    if rawget(query,joins) then
         joins = ' ' .. self:compileJoins(query,query.joins)
    end
    --// Of course, update queries may also be constrained by where clauses so we'll
    --// need to compile the where clauses and attach it to the query so only the
    --// intended records are updated by the SQL statements we generate to run.
    local where = self:compileWheres(query)
    return string.trim("update "..table..joins .." set "..columns .. " " .. where)

end
--
--/**
--* Compile a delete statement into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $values
--* @return string
--*/
function Grammar:compileDelete(query)
    local table = self:wrapTable(query.from)
    local where = array.is_array(query.wheres) and self:compileWheres(query) or ''
    return string.trim("delete from " .. table .." " .. where)
end
--
--/**
--* Compile a truncate table statement into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @return array
--*/

function Grammar:compileTruncate(query)
    return {['truncate '..self:wrapTable(query.from)]={}}
end

--
--/**
--* Compile the lock into SQL.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  bool|string  $value
--* @return string
--*/
function Grammar:compileLock(query,value)
    return string.is_string(value) and value or ''
end
--
--/**
--* Concatenate an array of segments, removing empties.
--*
--* @param  array   $segments
--* @return string
--*/
function Grammar:concatenate(segments)
    return array.implode(' ',array.filter(segments,function(value)
        return value ~= ''
    end))
end

--
--/**
--* Remove the leading boolean from a statement.
--*
--* @param  string  $value
--* @return string
--*/
function Grammar:removeLeadingBoolean(value)
   return string.preg_replace('and |or ','',value,1)
end

return Grammar


