module Tony
  class DialogInterface
    attr_accessor :vi

    def initialize(vi = nil)
      @vi = vi
    end

    def send
      raise 'Should be overriden by child classes'
    end
  end
end
