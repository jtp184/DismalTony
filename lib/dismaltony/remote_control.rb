module DismalTony
  class RemoteControl
    def self.from_yaml
    end
  end

  class RemoteControl
    attr_accessor :subject
    attr_accessor :predicates

    def initialize(**args)
      @subject = args[:subject]
      @predicates = args[:predicates]
    end
  end
end