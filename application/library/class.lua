--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-5-28
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local table_concat = table.concat
local table_remove = table.remove
local table_insert = table.insert
local table_sort = table.sort
local ngx_time = ngx.time
local string = require("library.string")
local randomseed = math.randomseed
local random = math.random


local _M = {}
--[[
--
--BaseClass = class("BaseClass", nil)

function BaseClass:ctor(param)
     print("baseclass ctor")
     self._param = param
     self._children = {}
end

function BaseClass:addChild(obj)
     table.insert(self._children, obj)
end

DerivedClass = class("DerivedClass", BaseClass)

function DerivedClass:ctor(param)
     print("derivedclass ctor")
end

local instance = DerivedClass.new("param1")
instance:addChild("child1")
 ]]

function _M.create(classname, super)
    local cls = {}
    if super then
        cls = {}
        for k,v in pairs(super) do cls[k] = v end
        cls.super = super
    else
        cls = {__construct = function() end}
    end

    cls.__cname = classname
    cls.__index = cls

    function cls.new(...)
        local instance = setmetatable({}, cls)
        local create
         create = function(c, ...)
            if c.super then -- 递归向上调用create
            create(c.super, ...)
            end
            if c.__construct then
                c.__construct(c, ...)
            end
         end
        create(instance, ...)
        instance.class = cls
        return instance
    end
    return cls
end


function _M.instanceof(instance, className)
    if  type(instance) ~= 'table' then
        return false
        end
    return instance.__cname == className
end

return _M


