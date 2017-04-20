module DismalTony
	class Scheduler

		def initialize(**opts)
			@vi = (opts[:vi] || DismalTony::VIBase.new)
		end

		def data_store
			@vi.data_store
		end

		def events
			self.data_store.load_events
		end

		def execute
			self.events.each do |event|
				event.run(@vi) if event.ready?
			end
		end

		def <<(other)
			self.data_store.add_event(other)
		end
	end

	class ScheduleEvent
		extend Forwardable

		attr_reader :time
		attr_reader :state
		attr_reader :query
		attr_reader :user_id

		def_delegators :@event_time, :<=>, :monday?, :tuesday?, :wednesday?, :thursday?, :friday?, :saturday?, :sunday?, :day, :sec, :hour, :day, :month, :year 

		def initialize(**opts)
			@time = (opts[:time] || Time.now)
			@finished = false
			@state = (opts[:state] || nil)
			@query = (opts[:query] || nil)
			@user_id = (opts[:user_id] || DismalTony::UserIdentity::DEFAULT)
		end

		def finished?
			@finished
		end

		def ready?
			!self.finished? and @time <= Time.now
		end

		def run(vi = DismalTony::VIBase.new)
			unless self.finished?
				@finished = true
				if state
					@user_id.modify_state!(state)
					vi.query!('', @user_id, true)
				elsif query
					vi.query!(query, @user_id, true)
				else
					DismalTony::HandledResponse.error.with_format(quiet: true)
				end
			end
		end

	end
end