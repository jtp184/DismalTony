require 'psych' # :nodoc:
require 'redis' # :nodoc:

module DismalTony # :nodoc:
  # Represents the collection of options and users that comprise the VI's memory.
  # The base DataStore class is a non-persistent Data Store that functions fine in IRB
  # or for ephemeral instances, but doesn't save anything.
  # If you don't specify a data store to use, this is the default.
  class DataStore
    # A Hash that stores any configuration options
    attr_reader :opts
    # an Array of UserIdentity objects that make up the userspace.
    attr_reader :users
    # A Hash that stores settings and records for directives
    attr_reader :directive_data

    # Initializes an empty store, and extracts data from +args+
    def initialize(args = {})
      @opts = {}
      @opts.merge!(args.fetch(:opts) { {} })
      @users = args.fetch(:users) { [] }
      @directive_data = args.fetch(:directive_data) { Hash.new({}) }
    end

    # Creates a new UserIdentity object with UserIdentity.user_data set to +opts+
    # and then stores it in the #users array before returning it
    def new_user(opts = {})
      noob = DismalTony::UserIdentity.new(user_data: opts)
      @users << noob
      noob
    end

    # A kickback method. This method is called on VIBase#data_store at the end of VIBase#query!
    # to perform cleanup tasks like updating users or saving data, and is passed values for the
    # HandledResponse +_response+, UserIdentity +_user+, and the +_data+ representation of the result
    # if available.
    def on_query(*args); end

    # Syntactic sugar. Selects users for whom +block+ returns true
    def select_user(&block)
      @users.select(&block)
    end

    # Calls <tt>#reject!</tt> on +user+
    def delete_user(user)
      @users.delete(user)
    end

    # Uses the hash +slug+ to insert a new value into the #directive_data hash
    def store_data(slug)
      dr = slug.fetch(:directive)
      ky = slug.fetch(:key)
      vl = slug.fetch(:value)
      @directive_data[dr] ||= {}
      @directive_data[dr][ky] = vl
    rescue KeyError
      nil
    end

    # Using the directive's +dname+ and the nested keys
    # +ky+, digs inside +directive_data+ for the information
    def read_data(dname, *ky)
      directive_data.dig(dname, *ky)
    end

    # Using the directive's +dname+ and the nested keys
    # +ky+, removes the key from the store
    def delete_data(dname, *ky)
      ini = directive_data[dname]
      jni = nil

      if ky.empty?
        ini
      elsif ky.length == 1
        ini.delete(ky.first)
      else
        ky.each do |j|
          jni = ini
          ini = j
        end
        jni.delete(ini)
      end
    end

    # Takes the +slug+ and modifies +directive_data+ accordingly
    def update_data(slug)
      dr = slug.fetch(:directive)
      ky = slug.fetch(:key)
      vl = slug.fetch(:value)
      @directive_data[dr] ||= {}
      @directive_data[dr][ky] = vl
    rescue KeyError
      nil
    end

    # Using the key +k+ and the value +v+, add something to the @opts hash
    def set_opt(k, v)
      @opts[k] = v
    end

    # Returns the @opts hash.
    def load_opts
      @opts
    end
  end

  # Represents storing the DataStore to disk in a YAML file. A relatively simple wrapper around
  # the internal DataStore that handles loading and saving the YAML.
  class YAMLStore
    # The location of the store on disk
    attr_reader :filepath
    # The wrapped DataStore object
    attr_reader :data_store

    # Args takes hooks for :filepath and :data_store, and autopopulates them if not present.
    def initialize(args = {})
      @filepath = args.fetch(:filepath) { './tony.yml' }
      @data_store = args.fetch(:data_store) { DataStore.new }
    end

    # Takes a filepath +fp+ and reads in that YAMLStore.
    def self.load_from(fp = './tony.yml')
      loaded = new(filepath: fp, data_store: Psych.load(File.read(fp)))
      loaded.opts[:env_vars]&.each_pair { |key, val| ENV[key] = val }
      loaded
    end

    # Creates a new YAMLStore at the filepath +fp+, and saves it to disk as well.
    def self.create_at(fp)
      new_store = new(filepath: fp)
      new_store.save
    end

    # Kickback function. Ignores +_args+ and saves to disk after every query.
    def on_query(*_args)
      save
    end

    # Overwrites the file at +filepath+ with the current data.
    def save
      File.open(filepath, 'w+') { |f| f << Psych.dump(data_store) }
      self
    end

    # Forcibly reloads the store
    def load
      load_from(filepath)
    end

    # Passes the +slug+ to DataStore#store_data and, then saves to disk.
    def store_data(slug)
      x = @data_store.store_data(slug)
      save
      x
    end

    # Using the directive's +dname+ and the nested keys
    # +ky+, digs inside +directive_data+ for the information
    def read_data(dname, *ky)
      x = @data_store.read_data(dname, *ky)
      save
      x
    end

    # Using the directive's +dname+ and the nested keys
    # +ky+, removes the key from the store
    def delete_data(dname, *ky)
      x = @data_store.delete_data(dname, *ky)
      save
      x
    end

    # Takes the data from the +slug+ and updates accordingly
    def update_data(slug)
      x = @data_store.update_data(slug)
      save
      x
    end

    # Delegates +k+ and +v+ to DataStore#set_opt and saves to disk.
    def set_opt(k, v)
      x = @data_store.set_opt(k, v)
      save
      x
    end

    # Checks the internal +data_store+ to see if it responds to +name+, and passes the +params+ along.
    def method_missing(name, *params)
      if @data_store.respond_to?(name)
        @data_store.method(name).call(*params)
      else
        super
      end
    end
  end

  # Uses Redis to store and retrieve user and directive data
  class RedisStore
    # The environment options, which get reloaded from the db
    attr_reader :opts

    # The string that opts uses, to dry up opts operations
    OPTS_PREFIX = 'DismalTony:RedisStore:opts'.freeze

    # takes in a :redis_config in +args+
    def initialize(args = {})
      @redis = Redis.new(args.fetch(:redis_config) { {} })
      load_opts
    end

    # Takes in options for the new user's UserIdentity#user_data through +args+
    def new_user(args = {})
      tu = DismalTony::UserIdentity.new(user_data: args)
      commit_user(serialize_out(tu))
      tu
    end

    # Takes the options in +args+ and doublesplats them.
    # Uses the user returned to update their model in the db
    def on_query(**args)
      user = args.fetch(:user)
      response = args.fetch(:response)
      commit_user(serialize_out(user))
      user = select_user(user[:uuid])
    end

    # If given a +uid+ that is a UserIdentity's uuid, returns that user.
    # Otherwise, passes a block argument to a select on #all_users
    def select_user(uid = nil, &block)
      if uid.nil? && block_given?
        all_users.select(&block)
      elsif !uid.nil?
        serialize_in(@redis.hgetall(user_key(uuid: uid)))
      end
    end

    # Given a +uid+, this passes the +user+ for editing
    # inside the +block+. Then commits the changes.
    def update_user(uid)
      # :yields: user
      u = select_user(uid)
      yield u
      commit_user(serialize_out(u))
      u
    end

    # Given any object +user+ which responds properly to #[:uuid],
    # deletes the associated hash and keys. Returns +user+ when done.
    def delete_user(user)
      ukey = user_key(user)
      to_delete = @redis.hgetall(ukey).keys
      @redis.pipelined { to_delete.each { |j| @redis.hdel(ukey, j) } }
      user
    end

    # Globs all the Users' keys and turns them into UserIdentity records.
    def all_users
      allofem = @redis.keys('DismalTony:UserIdentity:*')
      @redis.pipelined { allofem.map! { |a| @redis.hgetall(a) } }
      allofem.map!(&:value)
      allofem.map! { |a| serialize_in(a) }
      allofem
    end

    # Alias for #all_users
    def users
      all_users
    end

    # Yields an empty hash if read from directly.
    def directive_data
      {}
    end

    # Takes in the +slug+ and stores data in the db using the #directive_key method
    # to generate a hash string.
    def store_data(slug)
      dr = slug.fetch(:directive).to_s
      ky = slug.fetch(:key).to_s
      vl = Psych.dump(slug.fetch(:value))
      @redis.hset directive_key(dr), ky, vl
    rescue KeyError
      nil
    end

    # Takes in the +slug+ and stores data in the db using the #directive_key method
    # to generate a hash string.
    def update_data(slug)
      store_data(slug)
    end

    # Given the directive name +dname+ and any number of keys +ky+,
    # will dig through the hash and return values.
    def read_data(dname, *ky)
      if ky.empty?
        @redis.hgetall(directive_key(dname)).map { |_e, v| Psych.load(v) }
          .flatten
      elsif ky.length == 1
        initial = ky.shift
        s = Psych.load(@redis.hget(directive_key(dname), initial))
      else
        s = Psych.load(@redis.hget(directive_key(dname), initial))
        s.dig(*ky)
      end
    end

    # Given the directive name +dname+ and any number of keys +ky+,
    # will expunge the value from the hash.
    def delete_data(dname, *ky)
      ini = dname
      jni = nil

      if ky.empty?
        @redis.hdelall(directive_key(ini))
      elsif ky.length == 1
        @redis.hdel(directive_key(ini), ky.first)
      else
        ky.each do |j|
          jni = ini
          ini = j
        end
        @redis.hdel(directive_key(jni), ini)
      end
    end

    # Given a key-value pair +k+ and +v+, stores them in the db under the global
    # opts hash. Returns the whole array of opts
    def set_opt(k, v)
      @redis.hset(OPTS_PREFIX, k.to_s, Psych.dump(v))
      load_opts
    end

    # Removes the opt with key +k+ from the data store
    def delete_opt(k)
      @redis.hdel(OPTS_PREFIX, k)
      load_opts
    end

    # Directly adds the key-value pair +k+ and +v+ to the env_vars hash in opts
    def add_env_var(*glob)
      raise ArgumentError 'Must be hash-like' unless glob.respond_to?(:to_h)
      o = @redis.hget(OPTS_PREFIX, 'env_vars').clone
      o = Psych.load(o)

      glob.each_pair { |k, v| o[k.to_s] = v }

      @redis.hset(OPTS_PREFIX, 'env_vars', Psych.dump(o))
      load_opts
    end

    # Reads the opts in from the database and replaces +opts+ with them.
    def load_opts
      o = @redis.hgetall(OPTS_PREFIX).clone
      o.transform_keys!(&:to_sym)
      o.transform_values! { |v| Psych.load(v) }
      o[:env_vars]&.each_pair { |key, val| ENV[key.to_s] = val }
      @opts = o
    end

    private

    # Given hash +fields+, flattens them and sets them into the db
    def commit_user(fields)
      zipper = fields.to_a.flatten
      @redis.hmset user_key(fields), *zipper
    end

    # Takes in a UserIdentity and transforms it into a storable hash for Redis
    # by serializing complex data to YAML
    def serialize_out(model)
      hfields = {}
      hfields['conversation_state'] = Psych.dump(model.conversation_state)
      model.user_data.each do |hkey, hval|
        hfields[hkey.to_s] = Psych.dump(hval)
      end
      hfields['uuid'] = Psych.load(hfields['uuid'])
      hfields
    end

    # Reads the +redis_hash+ from db and undoes what #serialize_out does, yielding a UserIdentity.
    def serialize_in(redis_hash)
      h = redis_hash.clone
      h.transform_keys!(&:to_sym)
      h.transform_values! { |v| Psych.load v }
      cs = h.delete(:conversation_state)
      uid = DismalTony::UserIdentity.new(user_data: h, conversation_state: cs)
      uid
    end

    # Given a string +dk+, prepends it with "DismalTony:" to serve as a globbable identifier.
    def directive_key(dk)
      "DismalTony:#{dk}"
    end

    # Given +either+, which is anything that responds to ['uuid'], yields a key for identifying it in the db
    def user_key(either)
      "DismalTony:UserIdentity:#{either[:uuid] || either['uuid']}"
    end
  end
end
