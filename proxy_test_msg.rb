# frozen_string_literal: true

require 'logger'
# require 'byebug'

# Define our ProxyServer
class ProxyTestMsg
  def initialize(port, environment, module_model, msg)
    @environment = environment

    @model = module_model
    @server = TCPServer.new(port) if @number_of_runs == 0
    @msg = msg
    puts "hit initialize"
    @number_of_runs = 0
    # @log = Logger.new("log-#{@environment}-#{@model}.txt", 4, 1_024_000)
    # @log.debug "Listening on port #{port}\nReceived messages will be delivered to: \n#{generate_uri}"
  end


  def start
    # Start the server
    puts "Starting server on port"
    Socket.accept_loop(@server) do |connection|
      Thread.current.abort_on_exception = false
      Thread.new do

        loop do
          handle(connection, Time.now.utc.to_i)
        end
      end
    end
  end

  #Post Message to the server
  def post_to_server(msg, init_timestamp)
    puts "Sending message: #{msg}"
    # Create the request object to use
    
    uri, request = generate_http_obj(msg, init_timestamp)

    # Set the options
    req_options = { use_ssl: uri.scheme == 'https' }

    begin
      # Make the call
      puts "making the call"
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
        @server.close!
      end
      handle_response(response, init_timestamp)
      response.finish
      @number_of_runs = @number_of_runs + 1
    rescue StandardError => _e
      # @log.debug(e.message)
    end
  end

  private





  def generate_http_obj(msg, _init_timestamp)
    uri = generate_uri
    # @log.debug("(#{init_timestamp}) URL: #{uri}")

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json; charset=utf-8'
    request.body = data_prep(msg)
    # @log.debug("(#{init_timestamp}) Body: #{request.body}")

    [uri, request]
  end

  def generate_uri
    base = determine_domain
    path = determine_path
    full_url = "#{base}#{path}"
    URI.parse(full_url)
  end

  def determine_domain
    domain_hash = {
      'local': 'http://localhost:3000',
      'staging': 'https://staging-api.pumptrakr.com',
      'production': 'https://api.pumptrakr.com',
      'lee': 'https://rails.leehodges.work'
    }
    domain_hash[@environment.to_sym]
  end

  def determine_path
    path_hash = {
'GV600': '/api/v2/webhooks/modules/gv600_messages',
'GV620': '/api/v2/webhooks/modules/gv600_messages',
'GV350': '/api/v2/webhooks/modules/gv350_messages'
    }
    path_hash[@model.to_sym]

  end

  def data_prep(msg)
    { message: msg }.to_json
  end

  def handle_response(response, init_timestamp)
    # Check the status code
    if [200, 201, 204].include? response.code.to_i
      handle_successful(response, init_timestamp)
    else
      handle_error(response, init_timestamp)
    end
  end

  def handle_successful(response, init_timestamp)
    # Everything worked
    # @log.debug "(#{init_timestamp}) Successfully posted to PumpTrakr"
    # @log.debug "(#{init_timestamp}) Code: #{response.code}"
    # @log.debug "(#{init_timestamp}) Body: #{response.body}"
  end

  def handle_error(response, init_timestamp)
    # Error!
    # @log.debug "(#{init_timestamp}) Unsuccessfully posted to PumpTrakr"
    # @log.debug "(#{init_timestamp}) Code: #{response.code}"
    # @log.debug "(#{init_timestamp}) Body: #{response.body}"
  end
end
