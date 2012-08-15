require "socket"

class Countinual < Loggerish
  COUNTINUAL_HOST = "api.countinual.com"
  COUNTINUAL_PORT = 1025

  def self.args
    [
      [ "--countinual-key", "-k", GetoptLong::REQUIRED_ARGUMENT,
        "log to a Countinual account (API key)" ],
      [ "--countinual-counter", "-c", GetoptLong::REQUIRED_ARGUMENT,
        "Countinual counter (default is \"pullups\")" ],
    ]
  end

  def after_initialize
    if @enabled = !!@parent.config["countinual-key"]
      @parent.vputs "enabling Countinual logging module"

      if !@parent.config["countinual-counter"]
        @parent.config["countinual-counter"] = "pullups"
      end
    end
  end

  def log_pullup!(time)
    line = [
      @parent.config["countinual-key"],
      @parent.config["countinual-counter"],
      "+1",
      time.to_i,
    ].join(" ") + "\n"

    begin
      sock = UDPSocket.open                                                     
      sock.send(line, 0, COUNTINUAL_HOST, COUNTINUAL_PORT)
      @parent.vputs "logged pullup on countinual"
    rescue => e
      Rails.logger.info "Countinual error: #{e.message} (#{line.inspect})"     
    end
  end
end
