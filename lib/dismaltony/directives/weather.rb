require 'dismaltony/parsing_strategies/aws_comprehend_strategy'
require 'json'
require 'net/http'
require 'open-uri'

module DismalTony::DirectiveHelpers
  module OpenWeatherServicesHelpers
    include HelperTemplate

    module ClassMethods
      def all_weather_codes_yaml
        <<~DOC.freeze
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

      def data_struct_template
        @data_struct_template if @data_struct_template
        Struct::WeatherCode
      rescue NameError
        @data_struct_template = Struct.new('WeatherCode', :id, :flavor, :icon) do
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
            @@codes.find { |v| v.id == byid }
          end
        end
        Psych.load(all_weather_codes_yaml).each { |wc| @data_struct_template << wc }
        @data_struct_template
      end

      def api_url
        'http://api.openweathermap.org/data/2.5/weather?'
      end

      def api_defaults_proc
        Proc.new do |adef|
          adef[:APPID] = ENV['OPEN_WEATHER_API_KEY'] || ENV['open_weather_api_key']
          adef[:units] = 'imperial'
        end
      end
    end

    module InstanceMethods
      def get_weather_city(str)
        with_state = /, ([A-Z]+)/i
        str.gsub(with_state, '')
      end

      def retrieve_weather(loc)
        resp = api_request('q' => loc)
        if resp['weather']&.first.nil?
          raise IndexError, "No Weather in Response: #{resp.inspect}"
        end

        wc = data_struct_template.find(resp['weather'].first['id'])

        binding.pry

        {
          city_name: resp['name'],
          weather: wc,
          temp: resp['main']['temp'],
          temp_min: resp['main']['temp_min'],
          temp_max: resp['main']['temp_max'],
          humidity: resp['main']['humidity'],
          wind_speed: resp['wind']['speed']
        }
      end
    end
  end
end

module DismalTony::Directives
  class WeatherReportDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::OpenWeatherServicesHelpers

    set_name :get_weather
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/weather/i, /\brain/i) }
      qry << must(&:location?)
      qry << could { |q| q.key_phrases.any? { |ph| ph.text.match?(/\bweather\b/i) } }
    end

    def run
      req = retrieve_weather(get_weather_city(query.location.text))
      return_data(req)

      DismalTony::HandledResponse.finish("The current weather in #{req[:city_name]} is #{req[:weather].flavor}.").with_format(use_icon: req[:weather].icon)
    rescue IndexError
      return_data(nil)
      DismalTony::HandledResponse.finish("~e:#{negative_emoji} I'm sorry, I couldn't find results for #{query.location.text}.")
    end
  end

  class TemperatureReportDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::OpenWeatherServicesHelpers

    set_name :get_temperature
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/temperature/i, /\bhot\b/i, /\bcold\b/i) }
      qry << must(&:location?)
      qry << could { |q| q.contains?(/\bhot\b/i, /\bcold\b/i) }
      qry << could { |q| q.key_phrases.any? { |ph| ph.text.match?(/\btemperature\b/i) } }
    end

    def run
      req = retrieve_weather(get_weather_city(query.location.text))
      return_data(req)

      moj = temp_emoji(req[:temp])
      DismalTony::HandledResponse.finish("~e:#{moj} The temperature right now is around #{req[:temp]}˚F in #{req[:city_name]}")
    rescue IndexError
      return_data(nil)
      DismalTony::HandledResponse.finish("~e:#{negative_emoji} I'm sorry, I couldn't find results for #{query.location.text}.")
    end

    def temp_emoji(tmp)
      case tmp
      when 120..90
        random_emoji('fire', 'chartup', 'chili', 'exclamationmark', 'caution')
      when 90..80
        random_emoji('thermometer', 'tropicaldrink', 'globe')
      when 80..70
        random_emoji('sun', 'fish', 'flower', 'snail')
      when 70..60
        random_emoji('egg', 'smile', 'speechbubble')
      when 60..40
        random_emoji('smile', 'popcorn', 'pizza')
      when 40..35
        random_emoji('chartdown', 'coffee', 'shower')
      when 35..28
        random_emoji('snowflake', 'whiskey', 'worried')
      when 20..0
        random_emoji('snowflake', 'chartdown', 'snowflake')
      else
        random_emoji('mindblown', 'snowflake', 'cancel', 'thumbsdown')
      end
    end
  end

  class HumidityReportDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::OpenWeatherServicesHelpers

    set_name :get_humidity
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/humid(ity)?/i) }
      qry << must(&:location?)
      qry << could { |q| q.contains?(/level/i) }
      qry << could { |q| q.key_phrases.any? { |ph| ph.text.match?(/\bhumid(ity)?\b/i) } }
    end

    def run
      req = retrieve_weather(get_weather_city(query.location.text))
      return_data(req)

      moj = random_emoji('waterdrop', 'waterdrops')
      DismalTony::HandledResponse.finish("~e:#{moj} The humidity is currently at #{req[:humidity]}\% in #{req[:city_name]}")
    rescue IndexError
      return_data(nil)
      DismalTony::HandledResponse.finish("~e:#{negative_emoji} I'm sorry, I couldn't find results for #{query.location.text}.") end
  end

  class WindSpeedReportDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::DataStructHelpers
    include DismalTony::DirectiveHelpers::OpenWeatherServicesHelpers

    set_name :get_wind_speed
    set_group :info

    use_parsing_strategies do |use|
      use << DismalTony::ParsingStrategies::ComprehendSyntaxStrategy
      use << DismalTony::ParsingStrategies::ComprehendTopicStrategy
      use << DismalTony::ParsingStrategies::ComprehendKeyPhraseStrategy
    end

    add_criteria do |qry|
      qry << uniquely { |q| q.contains?(/\bwind\b/i) }
      qry << must(&:location?)
      qry << could { |q| q.contains?(/\bblow/i, /fast/i) }
      qry << could { |q| q.key_phrases.any? { |ph| ph.text.match?(/\bwind\b/i) } }
    end

    def run
      req = retrieve_weather(get_weather_city(query.location.text))
      return_data(req)

      moj = random_emoji('americanflag', 'windblow', 'gust')
      DismalTony::HandledResponse.finish("~e:#{moj} The wind is blowing at #{req[:wind_speed]}mph in #{req[:city_name]}.")
    rescue IndexError
      return_data(nil)
      DismalTony::HandledResponse.finish("~e:#{negative_emoji} I'm sorry, I couldn't find results for #{query.location.text}.")
    end
  end
end
