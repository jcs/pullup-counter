require "getoptlong"

$:.unshift(File.dirname(__FILE__))
require "lib/config_hash"
require "lib/loggerish"
require "lib/sensor/phidget"

# bring in all loggers
Dir.glob(File.dirname(__FILE__) << "/lib/logger/*.rb").sort.each do |f|
  require File.absolute_path(f)
end

class PullupCounter
  OPTS = [
    [ "--debug", "-d", GetoptLong::NO_ARGUMENT,
      "enable debugging (show sensor values)" ],
    [ "--help", "-h", GetoptLong::NO_ARGUMENT,
      "show this help" ],
    [ "--no-log", "-n", GetoptLong::NO_ARGUMENT,
      "don't actually log" ],
    [ "--verbose", "-v", GetoptLong::NO_ARGUMENT,
      "be verbose" ],
  ]

  attr_accessor :config, :loggers

  def initialize
    @config = ConfigHash.new

    # add in options from each logger
    @loggers = []
    opts = OPTS
    ObjectSpace.each_object(Class) do |cl|
      if cl < Loggerish && cl.args.any?
        @loggers.push cl
        opts += cl.args
      end
    end

    # put args into @config or show help
    GetoptLong.new(*opts.map{|o| o[0 ... -1] }).each do |opt,arg|
      case opt
      when "--help"
        puts "#{$0} [options]"
        opts.each do |o|
          print "    #{o[1]}\t#{o[0]}"
          
          tl = o[0].length
          if o[2] != GetoptLong::NO_ARGUMENT
            print "=<arg>"
            tl += 6
          end

          puts "\t" << (tl < 8 ? "\t" : "") << o[3]
        end
        
        exit 1

      else
        @config[opt.gsub(/^--/, "")] = arg.to_s == "" ? true : arg
      end
    end

    # initialize each logger and let it enable itself
    self.loggers.each_with_index do |cl,x|
      self.loggers[x] = cl.new(self)
    end

    Phidget.new(self).main_loop
  end

  # asynchronously send to each logger
  def log_pullup!(time)
    self.loggers.select{|l| l.enabled }.each do |logger|
      Thread.new do
        begin
          logger.log_pullup!(time)
        rescue => e
          puts "#{Time.now.to_f} - error from #{logger.class} logger: " <<
            e.message
        end
      end
    end
  end
end

PullupCounter.new
