# Dismal Tony

Dismal Tony is a gem I created that forms the framework for a system by which you can script human-language commands into actions with the Ruby programming language, using a Conversational Agent (called a "VI", or Virtual Intelligence). 

This Gem sets up a set of defaults, and a methodology that allows you to easily drop new commands into your workflow, and have the VI execute them easily. I designed it to be friendly and fun to engage with, while at the same time supporting all of Ruby's programming capability, to allow it to handle complex tasks with ease.


## Quickstart
Here's a snippet to get you started
```ruby
DismalTony::HandlerRegistry.load_handlers! './handlers'

tony = DismalTony::VIBase.new(
  :data_store => DismalTony::LocalStore.create('./store.yml')
)

identity = tony.data_store.new_user(name: '')

tony.("Hello", identity)
```

Add your handlers to that directory, and you should have a working VI. Read on if you're more interested in the nitty-gritty, or skip ahead to **Writing a Handler**.
## Basic VI
A VI is the unit that handles queries and users. A Very basic VI could be called like so:
```ruby
tony = DismalTony::VIBase.new
```
We could then attempt to query the VI
```ruby
result = tony.query!("Hello", identity)
```
If you don't supply an Identity, a default identity is used. This is generally good enough for any query that doesn't require user-specific information (e.g. checking the weather, saying hello).

You can also use #call and its .() syntax, resulting in a very succinct method call.
```ruby
sugar_result = tony.("Hello") 
```

But we wouldn't have any success as yet. The Handler Registry has to first load in handlers, and a VI will load them in by default. Otherwise, we just get a common error message printed to our console, used whenever we're unable to find matching handlers.
```
[🙁]: I'm sorry, I didn't understand that!
```

We can load handlers into the handler registry like this. This must be done once and only once before the first created VI. Therefore, if you're using a VI as part of a long-running persistent task (such as a Rails app) it is only necessary to load the handlers once during initialization. 

```ruby
DismalTony::HandlerRegistry.load_handlers! './handlers'
```

We can also configure our VI more extensively

```ruby
cassie = DismalTony::VIBase.new(
  :data_store => DismalTony::LocalStore.load_from('./store.yml'),
  :name => "Cassie",
  :handlers => DismalTony::HandlerRegistry.group('work'),
  :return_interface => DismalTony::SMSInterface.new(
    '8437427464'
  )
)
```

The VI consists of a name, a return_interface to reply across, its handlers, and a DataStore to retain its memories. All of these pieces are modular, and designed to be interchanged to fit your workflow. 

## Writing a Handler

Handlers are classes that you define in blocks, either one to a file or as many in one file as you'd like, dynamically or in static files that can be loaded in. This is a fairly robust starter one created from the generic QueryHandler class.
```ruby
# First we call the handler creator. 
# This starts a class evaluation with a special wrapper that will properly load it into the VI later.
DismalTony.create_handler do
  # handler_start runs as configuration for all handlers. You must define this method.
  def handler_start
    # The handler is given a unique name to recognize itself by. 
    # These can be used internally for redirection to other handlers, so care must be taken to ensure they are unique
    @handler_name = 'initial-setup'
    # Optionally, they can be given a group. Handlers whose group is the same can thus be subselected.
    # If no group is given, a handler is in the group 'none'
    @group = 'starters'
    # The patterns variable must be an array (of any length, including 1) 
    # holding Regexp or String objects corresponding to match patterns.
    # String arguments are automatically converted to Regexp of the form /arg/i
    @patterns = [/(begin|setup|start)/i]
    # Any patterns with named captures yield those captures to the data hash
    # Thus, for a Regexp /hello, my name is (?<name>\w+ \w+)/i
    # a successful parse query would define a value at @data['name']
    # You can therefore use named captures and the @data array to define handler 
    # logic within the matching pattern itself!
  end

  # Uses the same inputs as activate_handler!.
  # writing followup methods inside your handler is
  # great for short, contained multi-stage handlers.
  # Notice it too returns a HandledResponse.
  def get_name(query, user)
    @data['name'] = query
    user['nickname'] = query
    DismalTony::HandledResponse.finish("~e:thumbsup Great! You're all set up, #{user['nickname']}!")
  end

  # Just for readability.
  def message
    "Hello! I'm #{@vi.name}. I'm a virtual intelligence " \
    'designed for easy execution and automation of tasks.' \
    "\n\n" \
    "Let's start simple: What should I call you?"
  end

  # The non-bang version is used as a hypothetical.
  # It returns a single string that describes what the 
  # result of activating the handler would be.
  def activate_handler(query, user)
    "I'll do initial setup"
  end
  
  # The bang version runs the handler for a given query text and user.
  # You can explicitly call parse query to populate the @data array
   # here if you need to do and handling of message content
  def activate_handler!(query, user)
    # Keyword like syntax so you remember it.
    parse query
    # A HandledResponse must be the final return value of any Handler
    # This gives instructions about how to proceed after using the handler.
    # This one directs the VI send the message
    # then wait for user input, and route it to a handler-method pair.
    # This invokes self but could also be passed a String corresponding
    # to the handler_name.
    DismalTony::HandledResponse.then_do(self, 'get_name', message)
  end
end
```
### Subclasses
The subclass handlers let you write less code if you're following common patterns

#### Canned Responses
Canned responses lets you quickly pick between any of a set of options in response to a handler. Simple 1-to-1 call and response.

```ruby
DismalTony.create_handler(DismalTony::CannedResponse) do
  def handler_start
    @handler_name = 'greeter'
    @patterns = ["hello", "hello, #{@vi.name}"]
    @responses = ['~e:wave Hello!', '~e:smile Greetings!', '~e:rocket Hi!', '~e:star Hello!', '~e:snake Greetings!', '~e:cat Hi!', '~e:octo Greetings!', '~e:spaceinvader Hello!']
  end
end
```

#### Result Query
Result Queries can be accessed in the code as well as via direct query, allowing you to stack queries together.
```ruby
DismalTony.create_handler(DismalTony::QueryResult) do
  def handler_start
    @handler_name = "numtween"
    @patterns = [/print numbers between (?<start>\d+) and (?<end>\d+)/i]
  end

  def apply_format(input)
    result_string = "~e:smile Okay! Here they are: "
    result_string << input.join(', ')
  end

  def query_result(query, uid)
    parse query
    (@data['start'].to_i..@data['end'].to_i).to_a
  end
end
```

#### Query Menu
Query Menus let you present users with a list of options and follow them, allowing near infinite branching since the menu results are simply HandledResponses keyed to short choice strings

```ruby
DismalTony.create_handler(DismalTony::QueryMenu) do
  def handler_start
    @handler_name = 'animal-moji-menu'
    @patterns = [/impersonate an animal/i]

    add_option(:dog, DismalTony::HandledResponse.finish("~e:dog Woof!"))
    add_option(:cat, DismalTony::HandledResponse.finish("~e:cat Meow!"))
    add_option(:fish, DismalTony::HandledResponse.finish("~e:fish Glub!"))
  end

  def menu(query, user)
    opts = @menu_choices.keys.map { |e| e.to_s.capitalize }
    DismalTony::HandledResponse.then_do(self, "index", "~e:thumbsup Sure! You can choose from the following options: #{opts.join(', ')}")
  end
end
```

#### Query Service
A Query Service lets you define a bunch of mini-handlers. This is mostly designed to streamline other handlers by providing a simple method of grouping actions into a handler. Useful for integrating existing APIs.

```ruby
DismalTony.create_handler(DismalTony::QueryService) do
  def handler_start
    @handler_name = 'light'
    @actions = ['turn_on', 'turn_off', 'check_switch']
  end

  def switch_status
    # Imaginary API for a Smart Light Switch
    LightSwitch.status
  end

  def turn_on
    if self.switch_status
      DismalTony::HandledResponse.finish "~e:smile It's already on!"
    else
      DismalTony::HandledResponse.finish "~e:lightbulb Okay, I turned it on!"
    end
  end

  def turn_off
    if !self.switch_status
      DismalTony::HandledResponse.finish "~e:smile It's already off!"
    else
      DismalTony::HandledResponse.finish "~e:moon Okay, I turned it off."
    end
  end

  def check_switch
    if self.switch_status
      DismalTony::HandledResponse.finish "~e:lightbulb It's turne on right now!"
    else
      DismalTony::HandledResponse.finish "~e:lightbulb It's turned off right now"
    end
  end
```
You could then easily make a handler to use this new QueryService, and would probably choose to have them in the same .rb file.

```ruby
DismalTony.create_handler do 
  def handler_start
    @handler_name = 'light-switch'
    @patterns = [/turn (?:the )lights (?<switch>on|off)/i,/turn (?<switch>on|off)(?: the) lights/i]
  end

  def activate_handler(query, user)
    "~e:lightbulb I'll turn the lights #{@data['switch']}."
  end

  def activate_handler!(query, user)
    parse query
    case @data['switch']
    when 'on'
      # Special invocation for QueryService handlers. 
      # Doesn't gurantee a HandledResponse as a 
      # return value, our example case returns one.
      @vi.use_service('light', 'turn_on')
    when 'off'
      @vi.use_service('light', 'turn_off')
    else
      DismalTony::HandledResponse.error
    end
  end
end
```

## Storing Data
The DismalTony system allows you to store your users and user-data (necessary for multi-stage handlers) in different ways. 

### Methods
The DataStore classes follow basic CRUD concepts
```ruby
store = DismalTony::DataStore.new

usr = store.new_user
# => <DismalTony::UserIdentity>

ax = store.find { |u| u['first_name'] = "Aximili"}
# Same as running store.users.find

store.delete_user(ax)
# Same as running store.users.delete
```
Additionally, most Data Stores provide a `.save` or `.save(user)` function 

### Subclasses

#### DataStorage
The base DataStorage class is a non-persistent Data Store that functions fine in IRB or for ephemeral instances, but doesn't save anything. If you don't specify a data store to use, this is the default.

#### LocalStore
The LocalStore class exports the user space as a YAML document.
```ruby
# One that doesn't exist
DismalTony::LocalStore.create('./store.yml')

# One that does!
DismalTony::LocalStore.load_from('./store.yml')
```
If provided with a filepath during initialization, it will either create and load, or load that file. You can also call `.load` to load from the file specified by `local_store.opts[:filepath]`.

The LocalStore saves after every Query, but can be manually saved with `.save` which saves to its filepath variable.

#### DBStore
DBStore is designed to let you use ActiveRecord Models (or appropriately duck-typed Model classes), so that you can use a VI in a rails project by creating a Model. Check out [TonyRails](https://github.com/jtp184/tonyrails) for more information, but the DBStore Class is part of the Gem itself.

```ruby
DismalTony::DBStore.new(TheModel)
```

Saving is accomplished by passing an individual UserIdentity, not just calling `.save`. In general, the DBStore is geared around the idea that you'd be loading individual users using the Model class, but does have the ability to load all of the users by calling `.load_users!`.
