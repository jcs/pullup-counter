require "rubygems"
require "phidgets-ffi"

class Phidget
  attr_accessor :cur_value, :state, :fitbit

  # default values for each state to transition
  STATE_IDLE_TO_PULLING_UP = 150
  STATE_PULLING_UP_TO_PULLED_UP = 325
  STATE_PULLING_UP_TO_IDLE = 200
  STATE_PULLED_UP_TO_IDLE = 150

  def initialize(parent)
    @parent = parent
    @state = :idle
    @last_state_change = Time.now
    @cur_time = nil
  end

  def main_loop
    begin
      Phidgets::InterfaceKit.new do |ifkit|
        @parent.vputs "reading from Phidget #{ifkit.serial_number}"

        ifkit.on_sensor_change do |device, input, value, obj|
          @cur_time = Time.now
          if input.index == 1
            self.cur_value = value
          end
        end

        sleep
      end

    rescue => e
      @parent.eputs "exception in Phidget handler: #{e.message}"
      sleep 3
      retry
    end
  end

  def cur_value=(value)
    if @parent.config["debug"]
      # XXX: direct this somewhere so it doesn't get muxed with chatter
      STDOUT.puts "#{@cur_time.to_f},#{value}"
    end

    if @cur_time.to_i - @last_state_change.to_i > 10 && self.state != :idle
      # stuck in previous state, unlikely we're still hanging there, reset
      self.state = :idle
    end

    @cur_value = value

    case self.state
    when :idle
      if value >= STATE_IDLE_TO_PULLING_UP
        self.state = :pulling_up
      end

    when :pulling_up
      if value >= STATE_PULLING_UP_TO_PULLED_UP 
        self.state = :pulled_up
      elsif value <= STATE_PULLING_UP_TO_IDLE 
        self.state = :idle
      end

    when :pulled_up
      if value <= STATE_PULLED_UP_TO_IDLE
        self.state = :idle
      end
    end
  end

  def state=(state)
    @last_state_change = @cur_time

    if @state == state
      return
    end

    @state = state
    @parent.vputs "state is now #{state} (#{self.cur_value})"

    if state == :pulled_up
      @parent.log_pullup!(@cur_time)
    end
  end
end
