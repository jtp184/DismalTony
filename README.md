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
```

The VI consists of a name, a return_interface to reply across, its known Directives, and a DataStore to retain its memories. All of these pieces are modular, and designed to be interchanged to fit your workflow. 

## Writing a Directive

Directives are classes that you define in blocks, either one to a file or as many in one file as you'd like, dynamically or in static files that can be loaded in. Here is an example, the built in greeting Directive.
```ruby
module DismalTony::Directives
  class GreetingDirective < DismalTony::Directive
    # Sets the name of the directive. Must be unique.
    set_name :hello
    # Sets the group of the directive
    set_group :conversation


    # a block that yields an array to add new match logic criteria to.
    add_criteria do |qry|
      # the methods are generated from different MatchLogic classes 
      # which adjust how certain the VI is that it's correct in using this Directive
      qry << must { |q| q.contains?(/hello/i) || q.contains?(/greetings/i) }
      qry << should { |q| !q['rel', 'discourse'].empty?}
      qry << should { |q| !q['xpos', 'UH'].empty?}
    end

    # Every Directive has a run method, which does all of the work
    # of taking in the query and necessarily returning a HandledResponse as a result.
    def run
      # Uses built in query method
      if query =~ /how are you/i
        DismalTony::HandledResponse.finish("~e:thumbsup I'm doing well!")
      else
        DismalTony::HandledResponse.finish([
          '~e:wave Hello!',
          '~e:smile Greetings!',
          '~e:rocket Hi!',
          "~e:star Hello, #{query.user['nickname']}!",
          '~e:snake Greetings!',
          '~e:cat Hi!',
          "~e:octo Greetings, #{query.user['nickname']}!",
          '~e:spaceinvader Hello!'
          ].sample)
      end
    end
  end
```

DismalTony relies on you having [ParseyParse](http://github.com/jtp184/parseyparse) setup. If it doesn't detect a configured SyntaxNet, it will automatically decide it can't parse anything. See that repo for more information on configuring.

Due to ParseyParse being a dependency, MatchLogic queries can use the Natural Language Understanding properties to parse upon, such as finding parts of speech, inter-word dependencies, and roots of sentences.

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
The LocalStore class exports the user space as a YAML document.
```ruby
# One that doesn't exist
DismalTony::LocalStore.create_at('./store.yml')

# One that does!
DismalTony::LocalStore.load_from('./store.yml')
```
If provided with a filepath during initialization, it will either create and load, or load that file. You can also call `.load` to load from the file specified by `local_store.filepath`.

The LocalStore saves after every Query, but can be manually saved with `.save` which saves to its filepath variable.
