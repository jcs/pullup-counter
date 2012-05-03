class Textfile < Loggerish
  def self.args
    [
      [ "--file", "-f", GetoptLong::REQUIRED_ARGUMENT,
        "log to flat file <file>" ],
    ]
  end

  def after_initialize
    if @enabled = !!@parent.config["file"]
      @parent.vputs "enabling plaintext logging module to " <<
          @parent.config["file"]
    end
  end

  def log_pullup!(time)
    File.open(@parent.config["file"], "a") do |f|
      f.puts time.strftime("%Y-%m-%d %H:%M:%S")
    end
    
    @parent.vputs "logged to file " << @parent.config["file"]
  end
end
