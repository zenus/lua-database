--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-10
-- Time: 下午12:59
-- To change this template use File | Settings | File Templates.
--

--local string = require("application.library.string")
local array = require("library.array")
local class = require("library.class")
local tonumber = tonumber
local cjson = require("cjson")
local Processor = require("DB.Query.Processors.Processor")

local MysqlProcessor = class.create('MysqlProcessor',Processor)


function MysqlProcessor:__construct()
end
--
--    /**
--            * Process the results of a column listing query.
--*
--* @param  array  $results
--* @return array
--        */
function MysqlProcessor:processColumnListing(results)
    return array.map(
    function(r)
        return r.column_name
    end,
        results
    )
end

--
--/**
--* Process an  "insert get ID" query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  string  $sql
--* @param  array   $values
--* @param  string  $sequence
--* @return int
--*/
function MysqlProcessor:processInsertGetId(query,sql,values,sequence)

    local ret = query:getConnection():insert(sql,values)

    return tonumber(ret.insert_id)

end

return MysqlProcessor
