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

Retrieving A Single Column From A Row

```lua
local name = DB:table('users'):where('name', 'John'):pluck('name');
```
Retrieving A List Of Column Values

```lua
local role = DB:table('users'):lists('name');
```
Specifying A Select Clause

```lua
local users = DB:table('users'):select('name', 'email'):get();

local users = DB:table('users'):distinct():get();

local users = DB:table('users'):select('name as user_name'):get();
```
Adding A Select Clause To An Existing Query

```lua
local query = DB:table('users'):select('name');

local users = query:addSelect('age'):get();
```
Using Where Operators

```lua
local users = DB:table('users'):where('votes', '>', 100):get();
```
Or Statements

```lua
local users = DB:table('users')
                    :where('votes', '>', 100)
                    :orWhere('name', 'John')
                    :get();
```
Using Where Between

```lua
local users = DB:table('users')
                    :whereBetween('votes', array(1, 100)):get();
```

Using Where Not Between

```lua
local users = DB:table('users')
                    :whereNotBetween('votes', array(1, 100)):get();
```

Using Where In With An Array

```lua
local users = DB:table('users')
                    :whereIn('id', array(1, 2, 3)):get();

local users = DB::table('users')
                    :whereNotIn('id', array(1, 2, 3)):get();
```

Using Where Null To Find Records With Unset Values

```lua
local users = DB:table('users')
                    :whereNull('updated_at'):get();
```

Order By, Group By, And Having

```lua
local users = DB:table('users')
                    :orderBy('name', 'desc')
                    :groupBy('count')
                    :having('count', '>', 100)
                    :get();
```

Offset & Limit

```lua
local users = DB:table('users'):skip(10):take(5):get();
```

Joins

The query builder may also be used to write join statements. Take a look at the following examples:
Basic Join Statement

```lua
DB:table('users')
            :join('contacts', 'users.id', '=', 'contacts.user_id')
            :join('orders', 'users.id', '=', 'orders.user_id')
            :select('users.id', 'contacts.phone', 'orders.price')
            :get();
```

Left Join Statement

```lua
DB:table('users')
        :leftJoin('posts', 'users.id', '=', 'posts.user_id')
        :get();
```

You may also specify more advanced join clauses:

```lua
DB:table('users')
        :join('contacts', function(join)
        {
          return  join:on('users.id', '=', 'contacts.user_id'):orOn(...);
        })
        :get();
```

If you would like to use a "where" style clause on your joins, you may use the where and orWhere methods on a join. Instead of comparing two columns, these methods will compare the column against a value:

```lua
DB:table('users')
        :join('contacts', function(join)
        {
            return join:on('users.id', '=', 'contacts.user_id')
                 :where('contacts.user_id', '>', 5);
        })
        :get();
```

Advanced Wheres
Parameter Grouping

Sometimes you may need to create more advanced where clauses such as "where exists" or nested parameter groupings. The  query builder can handle these as well:

```lua
DB:table('users')
            :where('name', '=', 'John')
            :orWhere(function($query)
            {
               return query:where('votes', '>', 100)
                      :where('title', '<>', 'Admin');
            })
            :get();
```

The query above will produce the following SQL:

select * from users where name = 'John' or (votes > 100 and title <> 'Admin')

Exists Statements

```lua
DB:table('users')
            :whereExists(function(query)
            {
                return query:select(DB::raw(1))
                      :from('orders')
                      :whereRaw('orders.user_id = users.id');
            })
            :get();
```

The query above will produce the following SQL:

select * from users
where exists (
    select 1 from orders where orders.user_id = users.id
)

Aggregates

The query builder also provides a variety of aggregate methods, such as count, max, min, avg, and sum.
Using Aggregate Methods

```lua
local users = DB:table('users'):count();

local price = DB:table('orders'):max('price');

local price = DB:table('orders'):min('price');

local price = DB:table('orders'):avg('price');

local total = DB:table('users'):sum('votes');
```

Raw Expressions

Sometimes you may need to use a raw expression in a query. These expressions will be injected into the query as strings, so be careful not to create any SQL injection points! To create a raw expression, you may use the DB:raw method:
Using A Raw Expression

```lua
users = DB:table('users')
                     :select(DB:raw('count(*) as user_count, status'))
                     :where('status', '<>', 1)
                     :groupBy('status')
                     :get();
```

Inserts
Inserting Records Into A Table

```lua
DB:table('users'):insert(
    {email = 'john@example.com', votes = 0}
)
```

Inserting Records Into A Table With An Auto-Incrementing ID

If the table has an auto-incrementing id, use insertGetId to insert a record and retrieve the id:

```lua
local id = DB:table('users'):insertGetId(
    {email = 'john@example.com', votes = 0}
)
```

Note: When using PostgreSQL the insertGetId method expects the auto-incrementing column to be named "id".

Inserting Multiple Records Into A Table

```lua
DB:table('users'):insert(
    {
        {email = 'taylor@example.com', votes = 0},
        {email = 'dayle@example.com', votes = 0},
    }
)
```

Updates
Updating Records In A Table

```lua
DB:table('users')
            :where('id', 1)
            :update({votes => 1})
```

Incrementing or decrementing a value of a column

```lua
DB:table('users'):increment('votes');

DB:table('users'):increment('votes', 5);

DB:table('users'):decrement('votes');

DB:table('users'):decrement('votes', 5);
```

You may also specify additional columns to update:

```lua
DB:table('users'):increment('votes', 1, {name => 'John'});
```

Deletes
Deleting Records In A Table

```lua
DB:table('users'):where('votes', '<', 100):delete();
```

Deleting All Records From A Table

```lua
DB:table('users'):delete();
```

Truncating A Table

```lua
DB:table('users'):truncate();
```




