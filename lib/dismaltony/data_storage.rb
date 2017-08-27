require 'psych' # :nodoc:

module DismalTony # :nodoc:
  # Represents the collection of options and users that comprise the VI's memory.
  # The base DataStorage class is a non-persistent Data Store that functions fine in IRB
  # or for ephemeral instances, but doesn't save anything.
  # If you don't specify a data store to use, this is the default.
  class DataStorage
    # A Hash that stores any configuration options
    attr_accessor :opts
    # an Array of UserIdentity objects that make up the userspace.
    attr_reader :users
    # an Array of ScheduleEvent objects. Might be empty
    attr_reader :events

    # Initializes an empty store, and merges +args+ with #opts
    def initialize(**args)
      @opts = {}
      @opts.merge!(args) unless args.nil?
      @users = []
      @events = []
    end

    # Creates a new UserIdentity object with UserIdentity.user_data set to +opts+
    # and then stores it in the #users array before returning it
    def new_user(opts = {})
      noob = DismalTony::UserIdentity.new(user_data: opts)
      @users << noob
      noob
    end

    # A kickback method. This method is called on VIBase#data_store at the end of VIBase#query!
    # to perform cleanup tasks like updating users or saving data, and is passed the HandledResponse via +_handled+
    def on_query(_handled); end

    # Syntactic sugar. Selects users for whom +block+ returns true
    def select(&block)
      @users.select(&block)
    end

    # Calls <tt>#reject!</tt> on +user+
    def delete_user(user)
      @users.delete(user)
    end

    # Used to load the events from a store. Overridden by child classes.
    def load_events
      @events
    end

    # Used to add events to the store. Overridden by child classes.
    def add_event(the_event)
      @events << the_event
    end
  end

  # Represents storing the data to disk as a YAML file
  class LocalStore < DataStorage
    # Allows setting env_vars via manually editing the store file. Any values included in this hash will be merged with ENV
    attr_accessor :env_vars

    # Calls #load on the file +fp+
    def self.load_from(fp = '/')
      the_store = LocalStore.new(filepath: fp)
      the_store.load
      the_store
    end

    # Creates a new store at +fp+ and calls #save on the file
    def self.create(fp = '/')
      the_store = LocalStore.new(filepath: fp)
      the_store.save
      the_store
    end

    def new_user(opts = {}) # :nodoc:
      noob = DismalTony::UserIdentity.new(user_data: opts)
      @users << noob
      noob
    end

    # Every time a query is +_handled+, saves the YAML file
    def on_query(_handled)
      save
    end

    def initialize(**args) # :nodoc:
      super(args)
    end

    # Loads in an existing LocalStore using the file specified by <tt>opts[:filepath]</tt>
    def load
      enchilada = Psych.load File.open(@opts[:filepath])
      if @env_vars == enchilada['globals']['env_vars']
        @env_vars.each_pair { |key, val| ENV[key] = val }
      end
      @users = enchilada['users']
      enchilada['events'].each { |event| @events << event unless @events.include?(event) || event.finished? }
      @opts.merge!(enchilada['config']) do |k, o, n|
        if k == :filepath
          o
        else
          n
        end
        return true
      end
    rescue StandardError
      return false
    end

    # Exports the LocalStore to the file specified by <tt>opts[:filepath]</tt>
    def save
      output = { 'users' => @users, 'globals' => { 'config' => @opts, 'env_vars' => @env_vars }, 'events' => @events }
      begin
        File.open(@opts[:filepath], 'w+') do |fil|
          fil << Psych.dump(output)
        end
        return true
      rescue StandardError
        return false
      end
    end

    # Loads from the file first then returns the events visible.
    def load_events
      load
      @events
    end

    # Adds the event, then saves the file.
    def add_event(the_event)
      @events << the_event
      save
    end
  end

  # Designed to let you use ActiveRecord Models (or appropriately duck-typed Model classes),
  # so that you can use a VI in a rails project by creating a Model.
  class DBStore < DataStorage
    # The class to use for this model. It must implement all of the attributes of ConversationState as well as have a user_data column
    attr_reader :model_class

    # Instanciates this store using +mc+ as the #model_class and taking in normal +args+ options
    def initialize(mc, **args)
      @model_class = mc
      if @opts.nil?
        @opts = args
      else
        @opts.merge! args
      end
      @users = []
    end

    # Calls <tt>model_class.all</tt> and loads each user into the array.
    def load_users
      @model_class.all.each do |rec|
        @users << DBstore.to_tony(rec)
      end
      @users.uniq!
    end

    def new_user(opts = {}) # :nodoc:
      the_user = DismalTony::UserIdentity.new

      opts.each_pair { |key, value| the_user[key] = value }

      record = @model_class.new
      record.save

      the_user['id'] = record.id

      save the_user
      the_user
    end

    def on_query(handled) # :nodoc:
      handled.conversation_state.user_identity
    end

    # Syntactic sugar for <tt>DBStore.model_class.find</tt> with argument +num+
    def by_id(num)
      DBStore.to_tony @model_class.find(num)
    end

    # Syntactic sugar for <tt>DBStore.model_class.find_by</tt> with argument +params+
    def find(**params)
      record = @model_class.find_by(params)
      return nil if record.nil?
      DBStore.to_tony record
    end

    # Calls <tt>#destroy</tt> on the record corresponding to the +user+
    def delete_user(user)
      if user.is_a? DismalTony::UserIdentity
        the_usr = by_id(user['id'])
        @model_class.destroy(the_usr)
      else
        @model_class.destroy(user)
      end
    end

    # Transforms a +record+ into a UserIdentity object.
    # Extra columns in the model are neatly turned into UserIdentity#user_data entries
    def self.to_tony(record)
      skip_vals = %w[user_identity last_recieved_time idle use_next next_handler next_method next_args data_packet created_at updated_at user_data]

      cstate = DismalTony::ConversationState.new(
        last_recieved_time: record.last_recieved_time,
        idle: record.idle,
        use_next: record.use_next,
        next_handler: record.next_handler,
        next_method: record.next_method,
        next_args: record.next_args
      )

      packet = begin
        cstate.from_h(data_packet: Psych.load(record.data_packet))
      rescue
      end

      ud = (record.class.columns.map(&:name).reject { |e| skip_vals.include? e })

      uid = DismalTony::UserIdentity.new

      ud.each do |datum|
        uid[datum] = record.method(datum.to_sym).call
      end

      begin
        Psych.load(record.user_data).each_pair { |k, v| uid[k] = v }
      rescue TypeError
        puts 'Unable to load UserData'
      end

      uid.modify_state!(cstate)

      uid
    end

    # Takes a UserIdentity +tony_data+ and updates the database with the changes from its previous state.
    # Information in UserIdentity#user_data is unpacked into any matching columns on the Model class,
    # and any remaining data is converted to YAML format before being written to the Model's <tt>user_data</tt> column
    def save(tony_data)
      uid = tony_data
      cstate = uid.state
      skip_vals = %w[user_identity last_recieved_time idle use_next next_handler next_method next_args data_packet created_at updated_at user_data]

      the_mod = model_class.find_by(id: uid['id'])
      mod_cols = the_mod.class.columns.map(&:name)

      the_mod.last_recieved_time = cstate.last_recieved_time
      the_mod.idle = cstate.idle
      the_mod.use_next = cstate.use_next
      the_mod.next_handler = cstate.next_handler
      the_mod.next_method = cstate.next_method
      the_mod.next_args = cstate.next_args
      the_mod.data_packet = if cstate.data_packet.nil?
                              nil
                            else
                              Psych.dump(cstate.data_packet)
      end

      mod_cols.each do |col|
        next if skip_vals.include? col
        the_mod[col.to_sym] = uid[col]
      end

      remaining = {}

      uid.user_data.keys.each do |key|
        next if mod_cols.include? key
        remaining[key] = uid[key]
      end

      the_mod.user_data = Psych.dump(remaining)

      the_mod.save
    end
  end
end
