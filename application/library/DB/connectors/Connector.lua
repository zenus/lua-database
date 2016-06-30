--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-4
-- Time: 下午5:07
-- To change this template use File | Settings | File Templates.
--
--local array = require("library.array")
--local class = require("library.class")

local array = require("DB.helper.array")
local class = require("DB.hepler.class")

local Connector = class.create('Connector')

--local Connector = {}
--Connector.__index = Connector
--Connector.options = {}

function Connector:__construct()
   self.options = {}
end
--function Connector.new()
--    local self = setmetatable({}, Connector)
--          self.options = {}
--    return self
--end


--/**
--* Get the PDO options based on the configuration.
--*
--* @param  array  $config
--* @return array
--        */
--        public function getOptions(array $config)
--{
--$options = array_get($config, 'options', array());
--
--return array_diff_key($this->options, $options) + $options;
--}

function Connector:getOptions(config)
    local options = array.get(config,'options',{})
    return array.merge(self.options,options)
end


--/**
--* Create a new PDO connection.
--*
--* @param  string  $dsn
--* @param  array   $config
--* @param  array   $options
--* @return PDO
--*/
--public function createConnection($dsn, array $config, array $options)
--{
--$username = array_get($config, 'username');
--
--$password = array_get($config, 'password');
--
--return new PDO($dsn, $username, $password, $options);
--}
--
--/**
--* Get the default PDO connection options.
--*
--* @return array
--*/

  function Connector:getDefaultOptions()
      return self.options
  end



--
--/**
--* Set the default PDO connection options.
--*
--* @param  array  $options
--* @return void
--*/
--public function setDefaultOptions(array $options)
--{
--$this->options = $options;
--}

  function Connector:setDefaultOptions(options)
      self.options = options
  end

return Connector

