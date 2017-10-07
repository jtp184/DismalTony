module DismalTony
  module QueryResolver
    def self.match(query, directives)
      succeeds = directives.map { |d| [d, d =~ query] }
      succeeds.reject! { |d, p| p.nil? }
      succeeds.sort_by! { |d, p| p }
      raise NoDirectiveError, "No Matching Directive!" if succeeds.empty?
      succeeds
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

    def self.run_match(query, directives)
      begin
        result = match(query, directives).first.first
        result = result.from(query)
        result.call
      rescue NoDirectiveError
        Directive.error(query)
      end
    end

  def self.call(txt, vi)
    st8 = vi.user.clone.state

    if st8.idle?
      qry = query_from_text!(txt, vi.user)
      run_match qry, vi.directives
    else
      if st8.parse_next
        qry = query_from_text!(txt, vi.user)
      else
        qry = query_from_text(txt, vi.user)
      end
      res = DismalTony::Directives[st8.next_directive].new(qry)
      res.parameters = st8.data
      res.call
    end
  end
end
end