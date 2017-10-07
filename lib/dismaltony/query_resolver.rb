module DismalTony
  module QueryResolver
    def self.match(query, directives = DismalTony::Directives.all)
      succeeds = directives.map { |d| [d, d =~ query] }
      succeeds.reject! { |d, p| p.nil? }
      succeeds.sort_by! { |d, p| p }
    end

    def self.call(query, directives = DismalTony::Directives.all)
      result = match(query, directives).first.first
      result = result.new(query)
      result.call
    end

  end
end