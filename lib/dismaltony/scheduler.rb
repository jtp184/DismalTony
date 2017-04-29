module DismalTony #:nodoc:
  # The resolver for the Scheduling system
  # Loads events from a DataStorage object and handles their execution.
  class Scheduler
    # Configures using +opts+
    # * :vi - The VIBase to use to execute the events
    # * :failure_method - a Proc (or something with a #call) to run once per failed event
    def initialize(**opts)
      @vi = (opts[:vi] || DismalTony::VIBase.new)
      @failure_method = (opts[:failure_method] || nil)
    end

    # Syntactic sugar for <tt>@vi.data_store</tt>
    def data_store
      @vi.data_store
    end

    # Loads the events on #data_store
    def events
      data_store.load_events
    end

    # Main resolution method.
    # Iterates through the events, and handles them depending on event state.
    # Deletes successfully finished or failed events, calling <tt>@failure_method</tt> if it exists
    def execute
      events.each do |event|
        case event.state
        when :waiting
          event.run(@vi) if event.ready?
        when :success
          events.delete(event)
        when :failure
          failure_method.call if @failure_method
          events.delete(event)
        end
      end
    end

    # Shortcut method to append the event to the data_store
    def <<(other)
      data_store.add_event(other)
    end
  end

  # Represents the individual events to be scheduled and resolved.
  class ScheduleEvent
    extend Forwardable #:nodoc:

    # The Time object representing when to run this event
    attr_reader :time
    # The ConversationState object representing a state to put the UserIdentity in, if dropping into a handler chain.
    attr_reader :conversation_state
    # The state of the handler itself. either <tt>:waiting, :success, :failure</tt>
    attr_reader :state
    # A String which resolves to a query to put to the VI when the event runs if running a timed query
    attr_reader :query
    # The UserIdentity of the user who is invoking the event.
    attr_reader :user_id

    # Delegates time related functions to the #time object
    def_delegators :@time, :<, :>, :>=, :<=, :monday?, :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?, :sunday?, :day, :sec, :hour, :day, :month, :year

    # +opts+ initialization defaults
    # * :time - Defaults to Time.now
    # * :state - Defaults to :waiting
    # * :query - Defaults to nil
    # * :user_id - Defaults to the Default User
    def initialize(**opts)
      @time = (opts[:time] || Time.now)
      @finished = false
      @state = (opts[:state] || :waiting)
      @query = (opts[:query] || nil)
      @user_id = (opts[:user_id] || DismalTony::UserIdentity::DEFAULT)
    end

    # Syntactic sugar for checking the value of @finished
    def finished?
      @finished
    end

    # Fails the handler and returns false if it's been more than a minute since it was supposed to run
    # Otherwise, returns true if not finished, and our time is valid according to #=~
    def ready?
      failed if (@time + 60) < Time.now
      !finished? && self =~ Time.now
    end

    # Compares a ScheduleEvent +other+ and self with minute accuracy
    def ==(other)
      comp = other.time
      comp.year == @time.year && comp.month == @time.month && comp.day == @time.day && comp.hour == @time.hour && comp.min == @time.min
    end

    # Compares a ScheduleEvent to a Time object +other+ with minute accuracy (or uses #== if it's a ScheduleEvent)
    def =~(other)
      other == self if other.is_a? ScheduleEvent
      if other.is_a? Time
        other.year == @time.year && other.month == @time.month && other.day == @time.day && other.hour == @time.hour && other.min == @time.min
      end
    end

    # Compare our #time and #user_identity to +other+
    def eql?(other)
      other.time == time
      other.user_identity == user_identity
    end

    # Simple hash function just off of @time and @user_id
    def hash
      code = 17
      code = 37 * code + @time.hash
      code = 37 * code + @user_id.hash
    end

    # Changes our #state to :failure and returns false
    def failed
      @state = :failure
      false
    end

    # Executes this ScheduleEvent using the provided +vi+
    def run(vi = DismalTony::VIBase.new)
      unless finished?
        @finished = true
        @state = :success
        if @conversation_state
          @user_id.modify_state!(@conversation_state)
          vi.call('', @user_id, true)
        elsif @query
          vi.call(@query, @user_id, true)
        else
          DismalTony::HandledResponse.error.with_format(quiet: true)
        end
      end
    end

    # Simple output of the event
    def to_s
      "(#{@time.strftime('%m/%d/%Y %I:%M%p')}): #{@query if @query}#{@state if @state}"
    end
  end
end
