require 'uri'
require 'date'
require 'net/http'
require 'json'
require 'ostruct'

module DismalTony::Directives
  class GetStockPriceDirective < DismalTony::Directive
    include DismalTony::DirectiveHelpers::JSONAPIHelpers
    include DismalTony::DirectiveHelpers::ConversationHelpers
    include DismalTony::DirectiveHelpers::DataRepresentationHelpers
    include DismalTony::DirectiveHelpers::EmojiHelpers

    set_name :get_stock_price
    set_group :info

    add_param :stock_id
    add_param :current_value

    add_criteria do |qry|
      qry << keyword { |q| q =~ /stocks?/i }
      qry << must { |q| q =~ /\b[A-Z]+\b/ }
      qry << could { |q| q =~ /prices?/i }
    end

    add_synonyms do |make|
      make[/today's/i] = ['the current', "today's", 'the', 'current']
    end

    set_api_url 'https://www.alphavantage.co/query'

    set_api_defaults do |adef|
      adef[:function] = 'TIME_SERIES_DAILY'
      adef[:apikey] = ENV['alpha_vantage_key']
    end

    def run
      parameters[:stock_id] =
        /\b[A-Z]+\b/.match(query.raw_text)[0]
      prices = retrieve_data(symbol: parameters[:stock_id])

      parameters[:current_value] = prices.sort_by(&:date).last

      return_data(OpenStruct.new)

      data_representation.value = parameters[:current_value]
      data_representation.price = parameters[:current_value].price
      data_representation.symbol = parameters[:stock_id]

      answ, moj = price_comment(prices)

      conv = "~e:#{moj} "
      conv << synonym_for("today's").capitalize
      conv << " stock price for #{parameters[:stock_id]} is "
      conv << answ << '.'
      DismalTony::HandledResponse.finish(conv)
    end

    private

    StockPrice = Struct.new(:symbol, :date, :open, :high, :low, :close, :volume) do
      include Comparable

      def price
        close || open
      end

      def <=>(other)
        close <=> other.close
      rescue NoMethodError
        close <=> Integer(other)
      end

      def to_s
        price.to_s
      end

      def to_str
        price.to_s
      end
    end

    def price_comment(history)
      current = history.sort_by(&:date).last
      moj = ''

      comment = "$#{format('%.2f', current.price)}" << case [0, 1, 2, 3].sample
                                                       when 0
                                                         # Better / worse than yesterday
                                                         yesterday = history.sort_by(&:date).reverse[1]
                                                         if current > yesterday
                                                           moj = random_emoji('chartup', 'thumbsup', 'fire')
                                                           ", up from yesterday's $#{yesterday.price}"
                                                         else
                                                           moj = random_emoji('chartdown', 'raincloud', 'snail')
                                                           ", down from yesterday's $#{yesterday.price}"
                                                         end
                                                       when 1
                                                         # Compared to highest record
                                                         if history.max == current
                                                           moj = random_emoji('star', 'rocket', '100')
                                                           ', currently at its 100-day peak'
                                                         else
                                                           moj = random_emoji('barchart', 'chartup', 'checkbox')
                                                           ", with a 100-day peak of $#{history.max.price} on #{history.max.date}"
                                                         end
                                                       else
                                                         # Just the current price, no commentary
                                                         moj = random_emoji('moneywing', 'moneybag', 'monocle', 'tophat', 'dollarsign')
                                                         ''
       end
      [comment, moj]
     end

    def retrieve_data(qpr)
      parse_web_req(api_request(qpr))
    end

    def parse_web_req(resp)
      jsr = resp
      sym = jsr['Meta Data']['2. Symbol']
      slug = jsr.to_a[1].last

      results = []

      slug.each do |dat, prindx|
        md = /(\d+)-(\d+)-(\d+)/.match dat
        datum = Date.new(md[1].to_i, md[2].to_i, md[3].to_i)
        results << StockPrice.new(sym, datum, *prindx.values.map(&:to_f))
      end
      results
   end
  end
end
