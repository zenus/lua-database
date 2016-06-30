## lua Database

The lua Database component is a full database toolkit for lua, providing an expressive query builder, ActiveRecord style ORM, and schema builder. It currently only supports MySQL. It can serves as the database layer of any lua web framework.

### Usage Instructions

First, create a new Database manager instance.

```lua
    local DB = DatabaseManager.new()
```

Once the manager instance has been created. You may use it like so:

**Using The Query Builder**

```lua
local users = DB:table('users'):where('votes', '>', 100):get();
```
Other core methods may be accessed directly from the manager in the same manner as from the DB facade:

```lua
local results = DB:select('select * from users where id = ?', {1});
```


