class Loggerish
  attr_accessor :enabled

  def self.args
  end

  def initialize(parent)
    @parent = parent
    @enabled = false
    after_initialize
  end

  def after_initialize
  end

  def log_pullup!(time)
    @parent.aputs "logged pullup"
  end
end
