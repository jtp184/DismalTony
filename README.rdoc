# Dismal Tony

Dismal Tony is a gem I created that forms the framework for a system by which you can script human-language commands into actions with the Ruby programming language, using a Conversational Agent (called a "VI", or Virtual Intelligence). 

This Gem sets up a set of defaults, and a methodology that allows you to easily drop new commands into your workflow, and have the VI execute them easily. I designed it to be friendly and fun to engage with, while at the same time supporting all of Ruby's programming capability, to allow it to handle complex tasks with ease.


## Quickstart
The built-in VI will be created with any loaded Directives already loaded, so after loading any extra directives, simply posit a command
```ruby
require 'dismaltony/directives/stocks'

DismalTony.('How is AAPL stock doing today?')
```

Read on if you're more interested in the nitty-gritty of VI Initialization, or skip ahead to **Writing a Directive**.
## Basic VI
A VI is the unit that handles queries and users. A Very basic VI could be initialized like so:
```ruby
tony = DismalTony::VIBase.new
```
We could then attempt to send a text query to the VI using the #call alias
```ruby
result = tony.("Hello")
```
If you don't specify an identity, a default identity is used. This is generally good enough for any query that doesn't require user-specific information (e.g. checking the weather, saying hello).

If the VI Doesn't understand the query, it will reply with a generic error message.
```
[🙁]: I'm sorry, I didn't understand that!
```

We can also configure our VI more extensively

```ruby
cassie = DismalTony::VIBase.new(
  :data_store => DismalTony::YAMLStore.load_from('./store.yml'),
  :name => "Cassie",
  :directives => DismalTony::Directives.in_group('work'),
  :return_interface => DismalTony::SMSInterface.new(
    '+18437427464'
  )
)

# We can either set the module level VI to our new VI 
# and always have the DismalTony.() syntax use cassie
DismalTony.vi = cassie

# Or use cassie on her own!
cassie.('Hello, Cassie!')

```

The VI consists of a name, a return_interface to reply across, its known Directives, and a DataStore to retain its memories. All of these pieces are modular, and designed to be interchanged to fit your workflow. 

## Parsing Strategies

A Query object by default only contains the text value of the input. A Directive defines one or more Parsing Strategies that should be applied to the Query, whose methods are magically aliased onto the Query object for easy predicate matching. 

Built in are strategies for ParseyParse, my ParseyMcParseface decoder, as well as AWS Comprehend strategies for syntax, key phrases, and topic entities, and an IBM Watson Tone analyzer strategy.

```ruby
use_parsing_strategies do |use|
  use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
  use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
  use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
end
```

## Match Logic

Match Logic handlers are special keywords within the DSL which specify a truthy Proc to check the Query against and a priority to assign the match. The QueryResolver uses this to choose which Directive to activate on a query. Each Directive specifies its own Match Logics in a criteria block

```ruby
add_criteria do |qry|
  # Uniquely has the highest priority
  qry << uniquely { |q| q.contains?(/stocks?/i, /shares?/i) }
  # Uniquely and Must both cause a Directive to fail to match if their predicates don't
  qry << must(&:quantity?)
  qry << must(&:organization?)
  # A Could adds to the score but doesn't reduce it if unmatched
  qry << could { |q| q.contains(/shares?/i) }
end
```

## Writing a Directive

Directives are classes that you define in blocks, either one to a file or as many in one file as you'd like, dynamically or in static files that can be loaded in. Here is an example, the built in greeting Directive.
```ruby
module DismalTony::Directives
  class GreetingDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :hello
    set_group :core

    add_criteria do |qry|
      qry << must { |q| q =~ /hello/i || q =~ /\bhi\b/i || q =~ /greetings/i }
    end

    def run
      if /how are you/.match?(query)
        DismalTony::HandledResponse.finish("~e:thumbsup I'm doing well!")
      else
        moj = random_emoji(
          'wave',
          'smile',
          'rocket',
          'star',
          'snake',
          'cat',
          'octo',
          'spaceinvader'
        )
        resp = "#{synonym_for('hello').capitalize}"
        resp << ', ' << query.user[:nickname] if rand(4) <= 2
        resp << ['!', '.'].sample
        DismalTony::HandledResponse.finish("~e:#{moj} #{resp}")
      end
    end
  end
```

The salient parts of the Directive is that it must extend Directive, and be namespaced under Directives. This enables the built in enumeration to find it. A criteria block is also required, the more specific the better.

The run method is what is initially called when the directive is determined to be the correct one for the query. All Directive methods intended to be routed to by the QueryResolver must return a HandledResponse object, which carries the message to respond with as well as potential re-routing logic for multi-step queries.

## Fragments

The fragments data structure within Directives is intended to persist information across method calls, and between multi-step queries. It's easily accessed inside the Directive, and has some DSL methods to idiomatically write to it.

```ruby
# Declare expectations
expect_frags :product_number, :date

# Specify defaults
frag_default order: :asc

def the_action
  # Access the structure
  fragments[:date] = Time.now
  # Also has a shortcut
  frags[:product_number] = '9466'

  DismalTony::HandledResponse.then_do(
    message: 'Okay! How many should I order?',
    directive: DismalTony::Directives::OrderCountDirective,
    method: :set_count
    data: fragments
  )
end
```

## Handled Responses
There are two primary HandledResponses, `.finish` and `.then_do`. The former takes a single message argument, and resets the User's ConverstationState to a neutral one. The latter specifies next steps like directive, method, and data to pass between the Directive calls. 

```ruby
DismalTony::HandledResponse.finish('This is a simple response!')

DismalTony::HandledResponse.then_do(
        message: "~e:caution Please enter command code.",
        next_directive: self,
        method: :get_command_code,
        data: frags
      )
```

## Storing Data
The DismalTony system allows you to store your users and user-data (necessary for multi-stage handlers) in different ways. 

### Methods
The DataStore classes follow basic CRUD concepts
```ruby
store = DismalTony::DataStore.new

usr = store.new_user
# => <DismalTony::UserIdentity>

ax = store.select { |u| u['first_name'] = "Aximili"}

store.delete_user(ax)
# Same as running store.users.delete
```
Additionally, most Data Stores provide a `.save` or `.save(user)` function 

### Subclasses

#### DataStore
The base Datastore class is a non-persistent Data Store that functions fine in a REPL, but doesn't save anything. If you don't specify a data store to use, this is the default.

#### YAMLStore
The YAMLStore class exports the user space as a YAML document.
```ruby
# One that doesn't exist
DismalTony::YAMLStore.create_at('./store.yml')

# One that does!
DismalTony::YAMLStore.load_from('./store.yml')
```

If provided with a filepath during initialization, it will either create and load, or load that file. You can also call `.load` to load from the file specified by `local_store.filepath`.

The LocalStore saves after every Query, but can be manually saved with `.save` which saves to its filepath variable.

#### RedisStore
The RedisStore is used to connect to a Redis server and store and recall data. In general, it uses Redis hashes and YAML serialization to store information.

Due to its database backed nature, CRUD methods are necessary.

```ruby
jake = DismalTony.vi.data_store.select_user { |u| u[:last_name] = 'Berenson' }

DismalTony.vi.data_store.update_user(jake[:uuid]) do |u|
  u[:dogs_name] = 'Homer'
end

# Also sets env_vars

DismalTony.vi.data_store.add_env_var(amazing_api_key: 'asef78a087a6098w273yrtkj')
```
