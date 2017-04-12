require_relative '../module/utilities'

class Timer
  def initialize(time = 0, &block)
    self.time = time
    @block = block
  end

  def time=(time)
    @time = Time.now.utc + time
  end

  def set_action(&block)
    @block = block
  end

  def start
    Thread.new do
      while Time.now.utc < @time do
        sleep 1;
      end
      @block.call
    end
  end
end
