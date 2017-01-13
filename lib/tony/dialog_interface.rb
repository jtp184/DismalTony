class DialogInterface
  attr_accessor :VI

  def initialize(vi = nil)
    @vi = vi
  end

  def send
    raise 'Should be overriden by child classes'
  end
end
