module DismalTony
  class RemoteControl
    attr_accessor :subject
    attr_accessor :predicates

    def initialize(**args)
      @subject = args[:subject]
      @predicates = args[:predicates]
    end
  end
end