module DismalTony #:nodoc:
  # The class responsible for storing and retrieving ScheduleEvent objects
  class Scheduler
    def self.new_event(init_opts)
      ino = {}
      ino[:time] = init_opts.fetch(:time) { Time.now }
      ino[:query] = init_opts.fetch(:query) { '' }
      ino[:user_id] = init_opts.fetch(:user_id) { DismalTony.call.user[:uuid] }
      ino[:opts] = init_opts.fetch(:opts) { {} }
      e = ScheduleEvent.new(ino)
      store_event(e)
      e
    end

    def self.store_event(e)
      DismalTony.call.data_store.store_data(directive: :core_scheduler, key: "Event:#{e.event_id}", value: e)
    end

    def self.load_events
      DismalTony.call.data_store.read_data(:core_scheduler)
    end

    def self.ready_events
      e = load_events
      e.select(&:ready?)
    end

    def self.call
      e = load_events
      r = e.map(&:call)
      r.each do |f|
        DismalTony.call.data_store.update_data(directive: :core_scheduler, key: "Event:#{f.event_id}", value: f)
      end
      r
    end

    def self.wait
      loop do
        call
        prune_events
      end
    end

    def self.events_for_user(uid)
      e = load_events
      e.select { |f| f.user_id == uid }
    end

    def self.prune_events
      e = load_events
      e.each do |f|
        DismalTony.call.data_store.delete_data(:core_scheduler, "Event:#{f.event_id}") if f.finished?
      end
    end
  end

  # Represents the individual events to be scheduled and resolved.
  class ScheduleEvent
    extend Forwardable #:nodoc:

    # The Time object representing when to run this event
    attr_reader :time
    # The state of the handler itself. either <tt>:waiting, :success, :failure</tt>
    attr_reader :state
    # A String which resolves to a query to put to the VI when the event runs if running a timed query
    attr_reader :query
    # The uuid of the user who is invoking the event.
    attr_reader :user_id
    # A uuid for this event
    attr_reader :event_id
    # An array of options for the event
    attr_reader :opts

    # Delegates time related functions to the #time object
    def_delegators :@time, :<, :>, :>=, :<=, :monday?, :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?, :sunday?, :day, :sec, :hour, :day, :month, :year

    # +args+ options
    # * :time - Defaults to Time.now
    # * :state - Defaults to :waiting
    # * :query - Defaults to nil
    # * :user_id - The UUID of the user
    # * :opts - Defaults to an empty hash
    def initialize(**args)
      @time = args.fetch(:time) { Time.now }
      @finished = false
      @state = args.fetch(:state) { :waiting }
      @query = (args[:query] || nil)
      @user_id = args.fetch(:user_id) { nil }
      @opts = args.fetch(:opts) { {} }

      possible = (('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a)
      @event_id = (0..24).each_with_object([]) { |_n, i| i << possible.sample }.join
    end

    # Syntactic sugar, takes a hash +options+ and sets #opts equal to it
    def with_options(options)
      @opts = options
    end

    # Syntactic sugar for checking the value of @finished
    def finished?
      @finished
    end

    def expiry
      @expiry ||= @opts.fetch(:expiry) { 60 }
    end

    # Fails the handler and returns false if it's been more than a minute since it was supposed to run
    # Otherwise, returns true if not finished, and our time is valid according to #=~
    def ready?
      return failed if (time + expiry) < Time.now

      !finished? && self < Time.now
    end

    # Compares a ScheduleEvent +other+ and self with minute accuracy
    def ==(other)
      comp = other.time
      comp.to_i == @time.to_i
    end

    # Compares a ScheduleEvent to a Time object +other+ with minute accuracy (or uses #== if it's a ScheduleEvent)
    def =~(other)
      return other == self if other.is_a? ScheduleEvent

      other.to_i == @time.to_i if other.is_a? Time
    end

    def >(other)
      @time.to_i > other.to_i if other.is_a? Time
    end

    def <(other)
      @time.to_i < other.to_i if other.is_a? Time
    end

    # Compare our #time and #user_identity to +other+
    def eql?(other)
      other.time == time
      other.user_identity == user_identity
    end

    # Simple hash function just off of @time, @query, and @user_id
    def hash
      code = 17
      code = 37 * code + @time.hash
      code = 37 * code + @user_id.hash
      code = 37 * code + @query.hash
    end

    # Executes this ScheduleEvent,
    def run(vi = nil)
      unless finished?
        vi = construct_vi
        @finished = true
        @state = :success

        vi.call(@query)
        update_me
      end
      self
    end

    def call
      ready?
      run
    end

    # Simple output of the event
    def to_s
      "(#{@time.strftime('%m/%d/%Y %I:%M%p')}): #{@query}#{@state}"
    end

    private

    def construct_vi
      ocon = {}

      ocon[:user] = DismalTony.call.data_store.select_user(@user_id) if @user_id

      ocon[:return_interface] = @opts.fetch(:return_interface) if @opts.fetch(:return_interface) { false }

      ocon[:return_interface] = DismalTony::NowhereInterface.new if @opts.fetch(:quiet) { false }

      # if @opts.fetch(:) { false }
      # end

      DismalTony::VIBase.inherit(ocon)
    end

    def update_me
      Scheduler.store_event(self)
    end

    # Changes our #state to :failure and returns false
    def failed
      @finished = true
      @state = :failure
      update_me
      true
    end
  end
end
