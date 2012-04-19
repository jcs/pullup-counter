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
      if @parent.config["verbose"]
        puts "#{Time.now.to_f} - playing sound file " <<
          @parent.config["sound"]
      end

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

    if @parent.config["debug"]
      puts "#{Time.now.to_f} - running " << cmd.inspect
    end

    system(*cmd)
  end
end
