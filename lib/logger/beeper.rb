class Beeper < Loggerish
  attr_accessor :player

  def self.args
    [
      [ "--sound", "-s", GetoptLong::REQUIRED_ARGUMENT,
        "play <sound> file" ],
    ]
  end

  def after_initialize
    if @enabled = !!@parent.config["sound"]
      @parent.vputs "playing sound file " << @parent.config["sound"]

      if `uname -s`.strip == "OpenBSD"
        @player = [ "aucat", "-i" ]
      else
        # dunno, assume mac
        @player = [ "afplay" ]
      end
    end
  end

  def log_pullup!(time)
    cmd = @player + [ @parent.config["sound"] ]

    @parent.dputs "running " << cmd.inspect

    system(*cmd)
  end
end
