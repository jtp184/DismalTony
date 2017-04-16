require 'json'
require 'net/http'
require 'open-uri'

DismalTony.create_handler(DismalTony::QueryService) do
	def handler_start
		@handler_name = 'weather'
		@key = ENV['open_weather_api_key']
		@patterns = [/weather: (?<next>.+)/i]
		@actions = ['get_current_temp']
	end

	def get_current_temp(opts)
		resp = api_req(opts)
		{'city_name' => resp['name'], 'temp' => resp['main']['temp'], 'temp_min' => resp['main']['temp_min'], 'temp_max' => resp['main']['temp_max']}
	end

	def api_req(opts)
		web_addr = URI('http://api.openweathermap.org/data/2.5/weather?')
		opts['APPID'] = @key
		opts['units'] = 'imperial'
		web_addr.query = URI.encode_www_form(opts)
		JSON.parse(Net::HTTP.get(web_addr))
	end
end

DismalTony.create_handler(DismalTony::QueryResult) do
	def handler_start
		@handler_name = 'get-temperature'
		@patterns = [/how (?:hot|cold) is it (?:at|in) (?<location>[\w ]+)\??/i,/what is the temp(?:erature)? (?:at|in) (?<location>[\w ]+)\??/i]
	end

	def activate_handler(query, user)
		parse query
		"I'll tell you the temperature in #{@data['location']}"
	end

	def apply_format(input)
		result_string = "~e:thermometer Currently, in #{input['city_name']}, it is #{input['temp']}˚F"
	end

	def query_result(query, uid)
		parse query
		@vi.use_service(
			'weather',
			'get_current_temp',
			q: @data['location']
			)
	end
end