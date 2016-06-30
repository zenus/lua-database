--
-- Created by IntelliJ IDEA.
-- User: zenus
-- Date: 16-6-19
-- Time: 上午10:09
-- To change this template use File | Settings | File Templates.
--


--

--use Illuminate\Support\Contracts\JsonableInterface;
--use Illuminate\Support\Contracts\ArrayableInterface;

local cjson = require("cjson")
local array = require("library.array")
local string = require("library.string")
local class = require("library.class")
local pairs = pairs
local type = type
local sort = table.sort
local abs = math.abs
--
local Collection = class.create('Collection')


function Collection:__construct(items)
    self.items = items or {}
end
--
--/**
--* Create a new collection instance if the value isn't one already.
--*
--* @param  mixed  $items
--* @return \Illuminate\Support\Collection
--*/
function Collection:make(items)
    if not items then
--       todo make static object
        return Collection.new()
    end
    if class.instanceof(items,'Collection') then
        return items
    end
    local it = array.is_array(items) and items or {items}
    return Collection.new(it)
end
--
--/**
--* Get all of the items in the collection.
--*
--* @return array
--*/
function Collection:all()
    return self.items
end
--
--/**
--* Collapse the collection items into a single array.
--*
--* @return \Illuminate\Support\Collection
--*/
function Collection:collapse()

   local results = {}
   for _,values in pairs(self.items) do
       results = array.merge(results,values)
   end
   --       todo make static object
   return Collection.new(results)
end

--
--/**
--* Diff the collection with the given items.
--*
--* @param  \Illuminate\Support\Collection|\Illuminate\Support\Contracts\ArrayableInterface|array  $items
--* @return \Illuminate\Support\Collection
--*/
function Collection:diff(items)
    local diff = array.diff(self.items,items)
    --       todo make static object
   return Collection.new(diff)
end
--
--/**
--* Execute a callback over each item.
--*
--* @param  Closure  $callback
--* @return \Illuminate\Support\Collection
--*/
function Collection:each(callback)
   self = array.map(callback,self.items)
   return self
end
--
--/**
--* Fetch a nested element of the collection.
--*
--* @param  string  $key
--* @return \Illuminate\Support\Collection
--*/
function Collection:fetch(key)
    local items = array.fetch(self.items,key)
    return Collection.new(items)
end
--
--/**
--* Run a filter over each of the items.
--*
--* @param  Closure  $callback
--* @return \Illuminate\Support\Collection
--*/
function Collection:filter(callback)
    local items = array.filter(self.items,callback)
   return Collection.new(items)
end
--
--/**
--* Get the first item from the collection.
--*
--* @param  \Closure   $callback
--* @param  mixed      $default
--* @return mixed|null
--*/
function Collection:first(callback,default)
    if not callback then
        return array.count(self.items) > 0 and self.items or nil
    else
        return array.first(self.items,callback,default)
    end
end

--
--/**
--* Get a flattened array of the items in the collection.
--*
--* @return array
--*/
function Collection:flatten()
    local items = array.flatten(self.items)
   return Collection:new(items)
end
--
--/**
--* Remove an item from the collection by key.
--*
--* @param  mixed  $key
--* @return void
--*/
function Collection:forget(key)
    self.items[key] = nil
end
--
--/**
--* Get an item from the collection by key.
--*
--* @param  mixed  $key
--* @param  mixed  $default
--* @return mixed
--*/

function Collection:get(key,default)
    if self.items[key] then
        return self.items[key]
    end
    if type(default) == 'function' then
        return default()
    else
        return default
    end
end
--
--/**
--* Group an associative array by a field or Closure value.
--*
--* @param  callable|string  $groupBy
--* @return \Illuminate\Support\Collection
--*/
function Collection:groupBy(groupBy)

    local results = {}

    for key,value in pairs(self.items) do
        key = type(groupBy) == 'function' and groupBy(value,key) or value[groupBy]
        results[key][#results[key]+1]  =  value
    end

    return Collection:new(results)
end
--
--/**
--* Determine if an item exists in the collection by key.
--*
--* @param  mixed  $key
--* @return bool
--*/
function Collection:has(key)
    return self.items[key]
end
--
--/**
--* Concatenate values of a given key as a string.
--*
--* @param  string  $value
--* @param  string  $glue
--* @return string
--*/
function Collection:implode(value,glue)
   if not glue then
       return array.implode(self:lists(value))
   end
   return array.implode(glue,self:lists(value))
end

--
--/**
--* Intersect the collection with the given items.
--*
--* @param  \Illuminate\Support\Collection|\Illuminate\Support\Contracts\ArrayableInterface|array  $items
--* @return \Illuminate\Support\Collection
--*/
function Collection:intersect(items)
    local intersect = array.intersect(self.items,items)
    return Collection.new(intersect)
end
--
--/**
--* Determine if the collection is empty or not.
--*
--* @return bool
--*/
function Collection:isEmpty()
    return array.count(self.items) > 0
end
--
--/**
--* Get the last item from the collection.
--*
--* @return mixed|null
--*/
function Collection:last()
    local items = self.items
    return array.count(self.items) > 0 and array.last(items) or nil
end
--
--/**
--* Get an array with the values of a given key.
--*
--* @param  string  $value
--* @param  string  $key
--* @return array
--*/
function Collection:lists(value,key)
   return array.pluck(self.items,value,key)
end
--
--/**
--* Run a map over each of the items.
--*
--* @param  Closure  $callback
--* @return \Illuminate\Support\Collection
--*/
function Collection:map(callback)
   local items = array.map(callback,self.items,array.keys(self.items))
    return Collection:new(items)
end
--
--/**
--* Merge the collection with the given items.
--*
--* @param  \Illuminate\Support\Collection|\Illuminate\Support\Contracts\ArrayableInterface|array  $items
--* @return \Illuminate\Support\Collection
--*/
function Collection:merge(items)
    local items = array.merge(self.items,items)
    return Collection:new(items)
end
--
--/**
--* Get and remove the last item from the collection.
--*
--* @return mixed|null
--*/
function Collection:pop()
   return array.pop(self.items)
end
--
--/**
--* Push an item onto the beginning of the collection.
--*
--* @param  mixed  $value
--* @return void
--*/
function Collection:prepend(value)
    self = array.unshift(self.items,value)
end
--
--/**
--* Push an item onto the end of the collection.
--*
--* @param  mixed  $value
--* @return void
--*/
function Collection:push(value)
    self.items[#self.items+1] = value
end
--
--/**
--* Put an item in the collection by key.
--*
--* @param  mixed  $key
--* @param  mixed  $value
--* @return void
--*/
function Collection:put(key,value)
   self.items[key] = value
end
--
--/**
--* Reduce the collection to a single value.
--*
--* @param  callable  $callback
--* @param  mixed  $initial
--* @return mixed
--*/
function Collection:reduce(callback,initial)
   return array.reduce(self.items,callback,initial)
end
--
--/**
--* Get one or more items randomly from the collection.
--*
--* @param  int $amount
--* @return mixed
--*/
function Collection:random(amount)
    local keys = array.rand(self.items,amount)
    return array.is_array(keys) and array.intersect_key(self.items,array.flip(keys)) or self.items[keys]
end
--
--/**
--* Reverse items order.
--*
--* @return \Illuminate\Support\Collection
--*/
function Collection:reverse()
   local items = array.reverse(self.items)
    return Collection:new(items)
end

--
--/**
--* Get and remove the first item from the collection.
--*
--* @return mixed|null
--*/
function Collection:shift()
   local k,v =  array.shift(self.items)
    self.items[k] = nil
    return v
end
--
--/**
--* Slice the underlying collection array.
--*
--* @param  int   $offset
--* @param  int   $length
--* @param  bool  $preserveKeys
--* @return \Illuminate\Support\Collection
--*/
function Collection:slice(offset,length,preserveKeys)
   local items = array.slice(self.items,offset,length,preserveKeys)
    return Collection:new(items)
end
--
--/**
--* Chunk the underlying collection array.
--*
--* @param  int $size
--* @param  bool  $preserveKeys
--* @return \Illuminate\Support\Collection
--*/
function Collection:chunk(size,preserveKeys)

    local chunks = Collection:new()
    local items = array.chunk(self.items,size,preserveKeys)

    for _,chunk in pairs(items) do
        local obj = Collection:new(chunk)
        chunks:push(obj)
    end

    return chunks
end
--
--/**
--* Sort through each item with a callback.
--*
--* @param  Closure  $callback
--* @return \Illuminate\Support\Collection
--*/
function Collection:sort(callback)
   sort(self.items,callback)
   return self
end
--
--/**
--* Sort the collection using the given Closure.
--*
--* @param  \Closure|string  $callback
--* @param  int              $options
--* @param  bool             $descending
--* @return \Illuminate\Support\Collection
--*/
function Collection:sortBy(callback,descending)

    local results = {}

    if string.is_string(callback) then
        callback = self:valueRetriever(callback)
    end
    --// First we will loop through the items and get the comparator from a callback
    --// function which we were given. Then, we will sort the returned values and
    --// and grab the corresponding values for the sorted keys from this array.
    for key,value in pairs(self.items) do
        results[key] = callback(value)
    end

    if descending then
       results = array.arsort(results)
    else
       results = array.asort(results)
    end
    --// Once we have sorted all of the keys in the array, we will loop through them
    --// and grab the corresponding model so we can set the underlying items list
    --// to the sorted version. Then we'll just return the collection instance.
    local keys = array.keys(results)
    for _,key in pairs(keys) do
        results[key] = self.items[key]
    end
    self.items = results
    return self
end
--
--/**
--* Sort the collection in descending order using the given Closure.
--*
--* @param  \Closure|string  $callback
--* @param  int              $options
--* @return \Illuminate\Support\Collection
--*/
function Collection:sortByDesc(callback)
    return self:sortBy(callback,true)
end
--
--/**
--* Splice portion of the underlying collection array.
--*
--* @param  int    $offset
--* @param  int    $length
--* @param  mixed  $replacement
--* @return \Illuminate\Support\Collection
--*/
function Collection:splice(offset,length,replacement)
    length = length or 0
    replacement = replacement or {}
    local splices = array.splice(self.items,offset,length,replacement)
    return Collection:new(splices)
end

--
--/**
--* Get the sum of the given values.
--*
--* @param  \Closure  $callback
--* @param  string  $callback
--* @return mixed
--*/
function Collection:sum(callback)
   if string.is_string(callback) then
       callback = self:valueRetriever(callback)
   end
   return self:reduce(function(result,item)
       result = result + callback(item)
       return result
   end,0)
end

--
--/**
--* Take the first or last {$limit} items.
--*
--* @param  int  $limit
--* @return \Illuminate\Support\Collection
--*/

function Collection:take(limit)
   if limit < 0 then
       return self:slice(limit,abs(limit))
   end
   return self:slice(0,limit)
end
--
--/**
--* Transform each item in the collection using a callback.
--*
--* @param  Closure  $callback
--* @return \Illuminate\Support\Collection
--*/
function Collection:transform(callback)
    self = array.map(callback,self.items)
    return self
end
--
--/**
--* Return only unique items from the collection array.
--*
--* @return \Illuminate\Support\Collection
--*/
function Collection:unique()
   local items = array.unique(self.items)
    return Collection:new(items)
end
--
--/**
--* Reset the keys on the underlying array.
--*
--* @return \Illuminate\Support\Collection
--*/
function Collection:values()
    self.items = array.values(self.items)
    return self
end
--
--/**
--* Get a value retrieving callback.
--*
--* @param  string  $value
--* @return \Closure
--*/
function Collection:valueRetriever(value)
    return function(item)
       return item[value]
    end
end
--
--/**
--* Get the collection of items as a plain array.
--*
--* @return array
--*/
--function Collection:toArray()
--   return array.map(function(value)
--       return instanceof(value,ArrayableInterface) and value:toArray() or value
--   end,self)
--end
--
--/**
--* Get the collection of items as JSON.
--*
--* @param  int  $options
--* @return string
--*/
function Collection:toJson(options)
    options = options or 0
    return cjson.encode(self.items)
end
--
--/**
--* Get an iterator for the items.
--*
--* @return ArrayIterator
--*/
--public function getIterator()
--{
--return new ArrayIterator($this->items);
--}
--
--/**
--* Get a CachingIterator instance.
--*
--* @return \CachingIterator
--*/
--public function getCachingIterator($flags = CachingIterator::CALL_TOSTRING)
--{
--return new CachingIterator($this->getIterator(), $flags);
--}
--
--/**
--* Count the number of items in the collection.
--*
--* @return int
--*/
function Collection:count()
    return array.count(self.items)
end
--
--/**
--* Determine if an item exists at an offset.
--*
--* @param  mixed  $key
--* @return bool
--*/
--public function offsetExists($key)
--{
--return array_key_exists($key, $this->items);
--}
--
--/**
--* Get an item at a given offset.
--*
--* @param  mixed  $key
--* @return mixed
--*/
--public function offsetGet($key)
--{
--return $this->items[$key];
--}
--
--/**
--* Set the item at a given offset.
--*
--* @param  mixed  $key
--* @param  mixed  $value
--* @return void
--*/
--public function offsetSet($key, $value)
--{
--if (is_null($key))
--{
--$this->items[] = $value;
--}
--else
--{
--$this->items[$key] = $value;
--}
--}
--
--/**
--* Unset the item at a given offset.
--*
--* @param  string  $key
--* @return void
--*/
--public function offsetUnset($key)
--{
--unset($this->items[$key]);
--}
--
--/**
--* Convert the collection to its string representation.
--*
--* @return string
--*/
--public function __toString()
--{
--return $this->toJson();
--}
--
--/**
--* Results array of items from Collection or ArrayableInterface.
--*
--* @param  \Illuminate\Support\Collection|\Illuminate\Support\Contracts\ArrayableInterface|array  $items
--* @return array
--*/
--function  Collection:getArrayableItems(items)
--
--    if instanceof(items,Collection) then
--        items = items:all()
--    elseif instanceof(items,ArrayableInterface) then
--        items = items:toArray()
--    end
--    return items
--end

return Collection

