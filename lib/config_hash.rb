class ConfigHash
  CONFIG_FILE = "#{ENV["HOME"]}/.pullup_counter"

  def initialize
    @config = {}
    read
  end

  def [](var)
    @config[var]
  end

  def []=(var, val)
    @config[var] = val
  end

  def read
    @config = {}

    if File.exists?(CONFIG_FILE)
      File.read(CONFIG_FILE).split("\n").each do |line|
        if m = line.strip.match(/^([^=]+)=(.*)/)
          @config[m[1]] = m[2]
        end
      end
    end
  end

  def save!
    File.open(CONFIG_FILE, "w+", 0600) do |f|
      @config.each do |k,v|
        f.puts "#{k}=#{v}"
      end
    end
  end
end
