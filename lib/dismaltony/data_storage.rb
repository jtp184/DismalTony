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
		attr_accessor :env_vars

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
				if enchilada['globals']['env_vars']
					@env_vars = enchilada['globals']['env_vars']
					@env_vars.each_pair { |k, v| ENV[k] = v }
				end
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
			output = {'users' => @users, 'globals' => {'config' => @opts, 'env_vars' => @env_vars}}
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
			self.model_class.all.each do |rec|
				@users << DBstore.to_tony(rec)
			end
			@users.uniq!
		end

		def new_user(opts = {})
			the_user = DismalTony::UserIdentity.new
			the_user.user_data = opts

			record = self.model_class.new
			record.save

			the_user['id'] = record.id

			save the_user
			return the_user
		end

		def on_query(handled)
			uid = handled.conversation_state.user_identity
		end

		def self.by_id(num)
			DBStore.to_tony (self.model_class.find(num))
		end

		def find(**params)
			record = self.model_class.find_by(params)
			if record.nil?
				return nil
			else
				return DBStore.to_tony record
			end
		end

		def delete_user(user)
			if user.is_a? DismalTony::UserIdentity
				the_usr = self.by_id(user['id'])
				self.model_class.destroy(the_usr)
			else
				self.model_class.destroy(user)
			end
		end

		def self.to_tony(record)
			cstate = DismalTony::ConversationState.new
			skip_vals = ["user_identity", "last_recieved_time", "is_idle", "use_next", "return_to_handler", "return_to_method", "return_to_args", "data_packet", "created_at", "updated_at", "user_data"]

			cstate.last_recieved_time = record.last_recieved_time
			cstate.is_idle = record.is_idle
			cstate.use_next = record.use_next
			cstate.return_to_handler = record.return_to_handler
			cstate.return_to_method = record.return_to_method
			cstate.return_to_args = record.return_to_args
			cstate.data_packet = record.data_packet

			ud = ((record.class.columns.map {|e| e.name}).reject { |e| skip_vals.include? e})

			uid = DismalTony::UserIdentity.new

			ud.each do |datum|
				uid[datum] = record.method(datum.to_sym).call
			end

			Psych.load(record.user_data).each_pair { |k, v| uid[k] = v}

			uid.conversation_state = cstate

			return uid		
		end

		def save(tony_data)
			uid = tony_data
			cstate = uid.conversation_state
			skip_vals = ["user_identity", "last_recieved_time", "is_idle", "use_next", "return_to_handler", "return_to_method", "return_to_args", "data_packet", "created_at", "updated_at", "user_data"]

			the_mod = self.model_class.find_by(id: uid['id'])
			
			the_mod.last_recieved_time = cstate.last_recieved_time
			the_mod.is_idle = cstate.is_idle
			the_mod.use_next = cstate.use_next
			the_mod.return_to_handler = cstate.return_to_handler
			the_mod.return_to_method = cstate.return_to_method
			the_mod.return_to_args = cstate.return_to_args
			the_mod.data_packet = cstate.data_packet

			(the_mod.class.columns.map { |e| e.name}).each do |col|
				next if skip_vals.include? col
				the_mod[col.to_sym] = uid[col]
			end

			remaining = {}

			uid.user_data.keys.each do |key|
				next if (the_mod.class.columns.map { |e| e.name}).include? key
				remaining[key] = uid[key]
			end

			the_mod.user_data = Psych.dump(remaining)

			the_mod.save
		end
	end
end