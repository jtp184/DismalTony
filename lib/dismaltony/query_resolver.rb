module DismalTony
  module QueryResolver
    def self.match(query, directives)
      succeeds = self.match!(query, directives)
      succeeds.reject! { |d, p| p.nil? }
      succeeds.sort_by! { |d, p| p }.reverse!
      raise NoDirectiveError, "No Matching Directive!" if succeeds.empty?
      succeeds
    end

    def self.match!(query, directives)
      succeeds = directives.map { |d| [d, d =~ query] }
    end

    def self.query_from_text(txt, user)
      Query.new(
        :raw_text => txt,
        :user => user.clone
        )
    end

    def self.query_from_text!(txt, user)
      Query.new(
        :raw_text => txt,
        :parsed_result => ParseyParse.(txt),
        :user => user.clone
        )
    end

    def self.run_match(query, vi)
      begin
        result = match(query, vi.directives).first.first
        result = result.from(query, vi)
        result.call
      rescue NoDirectiveError
        Directive.error(query, vi)
      end
    end

  def self.call(txt, vi)
    st8 = vi.user.clone.state

    if st8.idle?
      qry = query_from_text!(txt, vi.user)
      run_match qry, vi
    else
      if st8.parse_next
        qry = query_from_text!(txt, vi.user)
      else
        qry = query_from_text(txt, vi.user)
      end
      res = DismalTony::Directives[st8.next_directive].new(qry, vi)
      res.parameters = st8.data
      res.call(st8.next_method.to_sym)
    end
  end
end
end