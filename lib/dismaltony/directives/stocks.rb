require 'uri'
require 'date'
require 'net/http'
require 'json'

module DismalTony::Directives
  class GetStockPriceDirective < DismalTony::Directive
    set_name :get_stock_price
    set_group :info

    add_param :stock_id
    add_param :current_value

    add_criteria do |qry|
      qry << keyword { |q| q =~ /stocks?/i }
      qry << must { |q| q =~ /\b[A-Z]+\b/ }
      qry << could { |q| q =~ /prices?/i }
    end

    def run
      parameters[:stock_id] =
        /\b[A-Z]+\b/.match(query.raw_text)[0]
      prices = retrieve_data(symbol: parameters[:stock_id])

      parameters[:current_value] = prices.find { |p| p.date === Date.today }

      answ, moj = price_comment(prices)

      conv = "~e:#{moj} "
      conv << ['The current', "Today's", 'The', 'Current'].sample
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
      current = history.select { |pr| pr.date === Date.today }.first
      moj = ''

      comment = "$#{format('%.2f', current.price)}" << case [0, 1, 2, 3].sample
                                                       when 0
                                                         # Better / worse than yesterday
                                                         yesterday = history.select { |pr| pr.date === Date.today - 1 }.first
                                                         if current > yesterday
                                                           moj = %w[chartup thumbsup fire].sample
                                                           ", up from yesterday's $#{yesterday.price}"
                                                         else
                                                           moj = %w[chartdown raincloud snail].sample
                                                           ", down from yesterday's $#{yesterday.price}"
                                                         end
                                                       when 1
                                                         # Compared to highest record
                                                         if history.max == current
                                                           moj = %w[star rocket 100].sample
                                                           ', currently at its 100-day peak'
                                                         else
                                                           moj = %w[barchart chartup checkbox].sample
                                                           ", with a 100-day peak of $#{history.max.price} on #{history.max.date}"
                                                         end
                                                       else
                                                         # Just the current price, no commentary
                                                         moj = %w[moneywing moneybag monocle tophat dollarsign].sample
                                                         ''
      end

      [comment, moj]
    end

    def retrieve_data(qpr)
      req = gen_web_req(qpr)
      resp = Net::HTTP.get_response(req)
      results = parse_web_req(resp)
    end

    def gen_web_req(qpr)
      uri = URI('https://www.alphavantage.co/query')
      req_params = {}

      req_params[:function] = 'TIME_SERIES_DAILY'
      req_params[:symbol] = qpr.fetch(:symbol) { raise ArgumentError, 'No Trading Symbol Provided' }
      req_params[:apikey] = ENV['alpha_vantage_key']

      uri.query = URI.encode_www_form(req_params)
      uri
    end

    def parse_web_req(resp)
      jsr = JSON.load(resp.body)
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
