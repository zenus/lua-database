--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-19
-- Time: 上午9:13
-- To change this template use File | Settings | File Templates.
--

local array = require("library.array")
local class = require("library.class")
local string = require("library.string")
local pcall = pcall

local Expression = class.create("Expression", nil)


--
--/**
--* Create a new raw query expression.
--*
--* @param  mixed  $value
--* @return void
--        */
function Expression:__construct(value)
    self.value = value
end
--
--/**
--* Get the value of the expression.
--*
--* @return mixed
--*/
function Expression:getValue()
    return self.value
end
--

return Expression
