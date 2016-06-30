## lua Database

The lua Database component is a full database toolkit for lua, providing an expressive query builder, ActiveRecord style ORM, and schema builder. It currently only supports MySQL. It can serves as the database layer of any lua web framework.

### Usage Instructions

First, create a new Database manager instance.

```lua
    local DB = DatabaseManager.new()
```

Once the manager instance has been created. You may use it like so:

**Using The Query Builder**


#Introduction

The database query builder provides a convenient, fluent interface to creating and running database queries. It can be used to perform most database operations in your application.

#Retrieving Results

Retrieving All Rows From A Table

To begin a fluent query, use the table method on the DB facade. The table method returns a fluent query builder instance for the given table, allowing you to chain more constraints onto the query and then finally get the results. In this example, let's just get all records from a table:

```lua
    local  users = DB:table('users')->get();
```
Retrieving A Single Row / Column From A Table

If you just need to retrieve a single row from the database table, you may use the first method.

```lua
local user = DB:table('users'):where('name', 'John'):first();
```



