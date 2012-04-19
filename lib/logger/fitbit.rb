require "oauth"
require "json"

class Fitbit < Loggerish
  def self.args
    [
      [ "--fitbit", "-F", GetoptLong::NO_ARGUMENT,
        "log to a Fitbit account (will walk through setup)" ],
    ]
  end

  def after_initialize
    if @enabled = !!@parent.config["fitbit"]
      if @parent.config["verbose"]
        puts "#{Time.now.to_f} - enabling Fitbit logging module"
      end

      verify_keys
    end
  end

  def log_pullup!(time)
    # TODO: update this to log to the user's custom tracker instead of an
    # activity, because activities don't allow custom units and logging pullups
    # in miles doesn't make any sense
    json = self.oauth_request("/1/user/-/activities.json", :post, {
      "activityName" => "Pullup",
      "manualCalories" => 1,
      "startTime" => time.strftime("%H:%M"),
      "durationMillis" => 1000,
      "date" => time.strftime("%Y-%m-%d"),
      "distance" => "1.0",
    })

    begin
      h = JSON.parse(json)
      if (id = h["activityLog"]["activityId"].to_i) != 0
        if @parent.config["verbose"]
          puts "#{Time.now.to_f} - logged pullup on fitbit (id #{id})"
        end
      else
        raise "no activity id"
      end

    rescue => e
      puts "#{Time.now.to_f} - error from fitbit (#{e.message}): " <<
        json.inspect
    end
  end

  def oauth_consumer
    OAuth::Consumer.new(@parent.config["fitbit_oauth_key"],
      @parent.config["fitbit_oauth_secret"],
      { :site => "http://api.fitbit.com", :http_method => :get })
  end

  def oauth_request(req, method = :get, post_data = nil)
    begin
      Timeout.timeout(20) do
        at = OAuth::AccessToken.new(oauth_consumer,
          @parent.config["fitbit_token"], @parent.config["fitbit_secret"])

        if method == :get
          res = at.get(req, { "Accept-Language" => "en_US" })
        elsif method == :post
          res = at.post(req, post_data, { "Accept-Language" => "en_US" })
        else
          raise "what kind of method is #{method}?"
        end

        if res.class.superclass != Net::HTTPSuccess
          raise res.class.to_s
        end

        return res.body
      end
    rescue Timeout::Error => e
      puts "#{Time.now.to_f} - timed out talking to Fitbit: #{e.message}"
    rescue StandardError => e
      puts "#{Time.now.to_f} - error talking to Fitbit: #{e.message}"
    end
  end

  def verify_keys
    while @parent.config["fitbit_oauth_key"].to_s == ""
      puts "No Fitbit OAuth key found.  Register an application at",
        "https://dev.fitbit.com/apps/new with PIN authentication and enter ",
        "the consumer key and secret here.",
        ""

      print "OAuth consumer key: "
      @parent.config["fitbit_oauth_key"] = STDIN.gets.strip
      print "OAuth consumer secret: "
      @parent.config["fitbit_oauth_secret"] = STDIN.gets.strip

      # this will be invalid now anyway
      @parent.config["fitbit_token"] = ""

      puts ""
    end

    while @parent.config["fitbit_token"].to_s == ""
      request_token = oauth_consumer.get_request_token

      puts "No Fitbit token found.  Authorize your Fitbit account at ",
        request_token.authorize_url,
        ""

      print "Enter the PIN received: "
      pin = STDIN.gets.strip

      access_token = request_token.get_access_token(:oauth_verifier => pin)
      if !access_token
        raise "couldn't get access token from pin"
      end

      @parent.config["fitbit_token"] = access_token.token
      @parent.config["fitbit_secret"] = access_token.secret

      @parent.config.save!

      puts ""
    end
  end
end
