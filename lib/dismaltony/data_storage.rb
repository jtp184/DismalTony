require 'psych'

module DismalTony
	class DataStorage
		attr_accessor :opts
		attr_accessor :users

		def initialize(**args)
			if @opts.nil?
				@opts = args
			else
				@opts.merge! args
			end
			@users = []
		end

		def new_user(opts = {})
			noob = DismalTony::UserIdentity.new(:user_data => opts)
			@users << noob
			return noob
		end

		def on_query(_handled); end

		def find(&block)
			@users.select(&block)
		end

		def delete_user(user)
			@users.reject! {|u| u == user}
		end
	end

	class LocalStore < DataStorage
		def self.load_from(fp = '/')
			the_store = LocalStore.new(:filepath => fp)
			the_store.load
			return the_store
		end

		def self.create(fp = '/')
			the_store = LocalStore.new(:filepath => fp)
			the_store.save
			return the_store
		end

		def new_user(opts = {})
			noob = DismalTony::UserIdentity.new(:user_data => opts)
			@users << noob
			return noob
		end

		def on_query(handled)
			save
		end

		def initialize(**args)
			if @opts.nil?
				@opts = args
			else
				@opts.merge! args
			end
			@users = []
		end

		def load
			begin
				enchilada = Psych.load File.open(@opts[:filepath])
				new_env = enchilada['globals']['env_vars'].merge!(ENV.to_h)
				new_env.each_pair { |k, v| ENV[k] = v}
				@users += (enchilada['users'])
				@opts.merge!(enchilada['config']) do |k, o, n|
					if k == :filepath
						o
					else
						n
					end
				end
				return true
			rescue Exception => e
				return false
			end
		end

		def save
			output = {'users' => @users, 'globals' => {'env_vars' => ENV.to_h, 'config' => @opts}}
			begin
				File.open(@opts[:filepath],'w+') do |f|
					f << Psych.dump(output)
				end
				return true
			rescue Exception => e
				return false
			end
		end
	end

	class DBStore < DataStorage
		attr_accessor :model_class

		def initialize(**args)
			if @opts.nil?
				@opts = args
			else
				@opts.merge! args
			end
			@users = []
		end

		def load_users!
			model_class.all.each do |rec|
				@users << DBstore.to_tony(rec)
			end
			@users.uniq!
		end

		def new_user(opts = {})
			the_user = DismalTony::UserIdentity.new
			the_user.data = opts

			the_user.to_rec.save
			return the_user
		end

		def on_query(handled)
			uid = handled.conversation_state.user_identity
		end

		def self.by_id(num)
			DBStore.to_tony (self.model_class.find(num))
		end

		def find(&block)
			DBStore.to_tony (self.model_class.find_by(&block))
		end

		def delete_user(user)
			if user.is_a? DismalTony::UserIdentity
				the_usr = self.by_id(user['id'])
				model_class.destroy(the_usr)
			else
				self.model_class.destroy(user)
			end
		end

		def self.to_tony(record)
			cstate = DismalTony::ConversationState.new
			cs_vals = ["user_identity", "last_recieved_time", "is_idle", "use_next", "return_to_handler", "return_to_method", "return_to_args", "data_packet"]

			cstate.last_recieved_time = record.last_recieved_time
			cstate.is_idle = record.is_idle
			cstate.use_next = record.use_next
			cstate.return_to_handler = record.return_to_handler
			cstate.return_to_method = record.return_to_method
			cstate.return_to_args = record.return_to_args
			cstate.data_packet = record.data_packet

			ud = record.columns.reject {|e| cs_vals.include? e}

			uid = DismalTony::UserIdentity.new

			ud.each do |datum|
				uid[datum] = record.datum
			end

			uid.conversation_state = cstate

			return uid		
		end

		def self.save(tony_data)
			uid = tony_data
			cstate = uid.conversation_state

			the_mod = model_class.find(uid['id'])
			
			the_mod.last_recieved_time = record.last_recieved_time
			the_mod.is_idle = record.is_idle
			the_mod.use_next = record.use_next
			the_mod.return_to_handler = record.return_to_handler
			the_mod.return_to_method = record.return_to_method
			the_mod.return_to_args = record.return_to_args
			the_mod.data_packet = record.data_packet

			remaining = {}

			uid.user_data.keys.each do |key|
				next if the_mod.columns.include? key
				remaining[key] = uid[key]
			end

			the_mod.user_data = Psych.dump(remaining)
		end
	end
end