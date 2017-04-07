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
		{'city_name' => resp['name'], 'temp' => resp['main']['temp']}
	end

	def api_req(opts)
		web_addr = URI('http://api.openweathermap.org/data/2.5/weather?')
		opts['APPID'] = @key
		opts['units'] = 'imperial'
		web_addr.query = URI.encode_www_form(opts)
		JSON.parse(Net::HTTP.get(web_addr))
	end

end