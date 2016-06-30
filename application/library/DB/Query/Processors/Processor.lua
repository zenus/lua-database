--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-10
-- Time: 上午11:57
-- To change this template use File | Settings | File Templates.
--
local string = require("DB.helper.string")
local class = require("DB.helper.class")
local cjson = require("cjson")
local Processor = class.create('Processor')



function Processor:__construct()
end
--
--    /**
--            * Process the results of a "select" query.
--*
--* @param  \Illuminate\Database\Query\Builder  $query
--* @param  array  $results
--* @return array
function Processor:processSelect(query,results)
    return results
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
function Processor:processInsertGetId(query,sql,values,sequence)

    query:getConnection():insert(sql,values)

    local id = query:getConnection():getConnect():lastInsertId(sequence)

    return string.tonumber(id)

end

--
--/**
--* Process the results of a column listing query.
--*
--* @param  array  $results
--* @return array
--*/

function Processor:processColumnListing(results)

   return results

end

return Processor

