--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-19
-- Time: 上午9:29
-- To change this template use File | Settings | File Templates.
--
local class = require("DB.helper.class")
local cjson = require("cjson")
local JoinClause = class.create('JoinClause')

--JoinClause.__index = JoinClause


--/**
--* Create a new join clause instance.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  string  $type
--* @param  string  $table
--* @return void
function JoinClause:__construct(query,type,table)
    self.clauses = {}
    self.type =type
    self.query = query
    self.table = table
end
--
--/**
--* Add an "on" clause to the join.
--*
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $second
--* @param  string  $boolean
--* @param  bool  $where
--* @return \Illuminate\Database\Query\JoinClause
--*/
function JoinClause:on(first,operator,second,boolean,where)
    local boolean = boolean or 'and'
    local where = where or false
    local compact = {first=first,operator=operator,second=second,boolean=boolean,where=where }
    self.clauses[#self.clauses+1] = compact
    if where then
        self.query:addBinding(second)
    end
    return self
end

--
--/**
--* Add an "or on" clause to the join.
--*
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $second
--* @return \Illuminate\Database\Query\JoinClause
--*/
function JoinClause:orOn(first,operator,second)
   return self:on(first,operator, second ,'or')
end
--
--/**
--* Add an "on where" clause to the join.
--*
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $second
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\JoinClause
--*/
function JoinClause:where(first,operator,second,boolean)
    boolean = boolean or 'and'
    return self:on(first,operator,second,boolean,true)
end
--
--/**
--* Add an "or on where" clause to the join.
--*
--* @param  string  $first
--* @param  string  $operator
--* @param  string  $second
--* @param  string  $boolean
--* @return \Illuminate\Database\Query\JoinClause
--*/
function JoinClause:orWhere(first,operator,second)
    return self:on(first,operator,second,'or',true)
end
--
--}
--
return JoinClause

