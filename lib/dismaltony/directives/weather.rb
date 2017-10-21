require 'json'
require 'net/http'
require 'open-uri'

module DismalTony::Directives
  class WeatherReportDirective < DismalTony::Directive
    WeatherCodeYAML = <<DOC
---
- !ruby/struct:Struct::WeatherCode
  id: 200
  flavor: thunderstorm with light rain
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 201
  flavor: thunderstorm with rain
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 202
  flavor: thunderstorm with heavy rain
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 210
  flavor: light thunderstorm
  icon: "🌩"
- !ruby/struct:Struct::WeatherCode
  id: 211
  flavor: thunderstorm
  icon: "🌩"
- !ruby/struct:Struct::WeatherCode
  id: 212
  flavor: heavy thunderstorm
  icon: "🌩"
- !ruby/struct:Struct::WeatherCode
  id: 221
  flavor: ragged thunderstorm
  icon: "🌩"
- !ruby/struct:Struct::WeatherCode
  id: 230
  flavor: thunderstorm with light drizzle
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 231
  flavor: thunderstorm with drizzle
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 232
  flavor: thunderstorm with heavy drizzle
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 300
  flavor: light intensity drizzle
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 301
  flavor: drizzle
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 302
  flavor: heavy intensity drizzle
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 310
  flavor: light intensity drizzle rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 311
  flavor: drizzle rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 312
  flavor: heavy intensity drizzle rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 313
  flavor: shower rain and drizzle
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 314
  flavor: heavy shower rain and drizzle
  icon: "☔️"
- !ruby/struct:Struct::WeatherCode
  id: 321
  flavor: shower drizzle
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 500
  flavor: light rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 501
  flavor: moderate rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 502
  flavor: heavy intensity rain
  icon: "☔️"
- !ruby/struct:Struct::WeatherCode
  id: 503
  flavor: very heavy rain
  icon: "☔️"
- !ruby/struct:Struct::WeatherCode
  id: 504
  flavor: extreme rain
  icon: "☔️"
- !ruby/struct:Struct::WeatherCode
  id: 511
  flavor: freezing rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 520
  flavor: light intensity shower rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 521
  flavor: shower rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 522
  flavor: heavy intensity shower rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 531
  flavor: ragged shower rain
  icon: "🌧"
- !ruby/struct:Struct::WeatherCode
  id: 600
  flavor: light snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 601
  flavor: snow
  icon: "❄️"
- !ruby/struct:Struct::WeatherCode
  id: 602
  flavor: heavy snow
  icon: "❄️"
- !ruby/struct:Struct::WeatherCode
  id: 611
  flavor: sleet
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 612
  flavor: shower sleet
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 615
  flavor: light rain and snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 616
  flavor: rain and snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 620
  flavor: light shower snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 621
  flavor: shower snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 622
  flavor: heavy shower snow
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 701
  flavor: mist
  icon: "🌫"
- !ruby/struct:Struct::WeatherCode
  id: 711
  flavor: smoke
  icon: "🌫"
- !ruby/struct:Struct::WeatherCode
  id: 721
  flavor: haze
  icon: "🌫"
- !ruby/struct:Struct::WeatherCode
  id: 731
  flavor: sand, dust whirls
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 741
  flavor: fog
  icon: "🌫"
- !ruby/struct:Struct::WeatherCode
  id: 751
  flavor: sand
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 761
  flavor: dust
  icon: "🌫"
- !ruby/struct:Struct::WeatherCode
  id: 762
  flavor: volcanic ash
  icon: "🌋"
- !ruby/struct:Struct::WeatherCode
  id: 771
  flavor: squalls
  icon: "🌬"
- !ruby/struct:Struct::WeatherCode
  id: 781
  flavor: tornado
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 800
  flavor: clear sky
  icon: "☀️"
- !ruby/struct:Struct::WeatherCode
  id: 801
  flavor: few clouds
  icon: "🌤"
- !ruby/struct:Struct::WeatherCode
  id: 802
  flavor: scattered clouds
  icon: "🌤"
- !ruby/struct:Struct::WeatherCode
  id: 803
  flavor: broken clouds
  icon: "🌤"
- !ruby/struct:Struct::WeatherCode
  id: 804
  flavor: overcast clouds
  icon: "🌥"
- !ruby/struct:Struct::WeatherCode
  id: 900
  flavor: tornado
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 901
  flavor: tropical storm
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 902
  flavor: hurricane
  icon: "🌪"
- !ruby/struct:Struct::WeatherCode
  id: 903
  flavor: cold
  icon: "❄️"
- !ruby/struct:Struct::WeatherCode
  id: 904
  flavor: hot
  icon: "🔥"
- !ruby/struct:Struct::WeatherCode
  id: 905
  flavor: windy
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 906
  flavor: hail
  icon: "🌨"
- !ruby/struct:Struct::WeatherCode
  id: 951
  flavor: calm
  icon: "☀️"
- !ruby/struct:Struct::WeatherCode
  id: 952
  flavor: light breeze
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 953
  flavor: gentle breeze
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 954
  flavor: moderate breeze
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 955
  flavor: fresh breeze
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 956
  flavor: strong breeze
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 957
  flavor: high wind, near gale
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 958
  flavor: gale
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 959
  flavor: severe gale
  icon: "💨"
- !ruby/struct:Struct::WeatherCode
  id: 960
  flavor: storm
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 961
  flavor: violent storm
  icon: "⛈"
- !ruby/struct:Struct::WeatherCode
  id: 962
  flavor: hurricane
  icon: "🌪"
DOC
end

  class WeatherReportDirective < DismalTony::Directive
    set_name :get_weather
    set_group :info

    add_param :location
    add_param :id_code
    add_param :flavor
    add_param :icon

    add_criteria do |qry|
      qry << must { |q| q.contains?(/weather/i, /temperature/i) }
      qry << should { |q| q.root =~ /weather/i || q.root =~ /temperature/i}
    end

    WeatherCode = Struct.new('WeatherCode', :id, :flavor, :icon) do
      include Enumerable
      @@codes = []

      def self.[](param)
        @@codes[param]
      end

      def self.<<(member)
        @@codes << member
      end

      def self.each
        @@codes.each { |c| yield c }
      end

      def self.all
        @@codes
      end

      def self.find(byid)
        @@codes.find { |v| v.id == byid}
      end

    end
    
    Psych.load(WeatherCodeYAML).each { |wc| WeatherCode << wc }

    def api_req(opts)
      web_addr = URI('http://api.openweathermap.org/data/2.5/weather?')
      opts['APPID'] = ENV['open_weather_api_key']
      opts['units'] = 'imperial'
      opts['q'] = opts[:location]
      opts.delete(:location)
      web_addr.query = URI.encode_www_form(opts)
      JSON.parse(Net::HTTP.get(web_addr))
    end

    def retrieve_for(loc)
      resp = api_req(location: loc)
      {
        city_name: resp['name'],
        weather: WeatherCode.find(resp['weather'].first['id']),
        temp_min: resp['main']['temp_min'],
        temp_max: resp['main']['temp_max'],
      }
    end

    def run
      parameters[:location] = query['xpos', 'NNP'].join(' ')
      req = retrieve_for(parameters[:location])

      reply = if query.contains?(/temperature/i)
        "~e:thermometer The temperature right now is around #{req[:temp_min]}˚F in #{req[:city_name]}"
      else
        "~e:#{DismalTony::EmojiDictionary.name(req[:weather].icon)} The current weather in #{req[:city_name]} is #{req[:weather].flavor}"
      end

      DismalTony::HandledResponse.finish(reply)
    end
  end
end