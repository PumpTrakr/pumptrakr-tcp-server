# frozen_string_literal: true

require 'logger'

# Define our ProxyServer
class ProxyServer
  def initialize(port, environment, module_model)
    @environment = environment
    @model = module_model
    @server = TCPServer.new(port)
    @log = Logger.new("log-#{@environment}-#{@model}.txt", 'daily')
    @log.debug "Listening on port #{port}\nReceived messages will be delivered to: \n#{generate_uri}"
  end

  def start
    Socket.accept_loop(@server) do |connection|
      Thread.new do
        Thread.current.abort_on_exception = false
        loop do
          handle(connection, Time.now.utc.to_i)
        end
      end
    end
  end

  private

  def handle(connection, init_timestamp)
    Thread.exit if connection.closed?
    @log.debug("(#{init_timestamp}) Handle initiation")

    # Read from the socket until it ends
    msg = extract_message(connection, init_timestamp)
    @log.debug("(#{init_timestamp}) extracted message: #{msg}")

    if msg.nil?
      connection.close
      Thread.exit
    end

    if empty_string?(msg, init_timestamp)
      @log.debug("(#{init_timestamp}) Message received, empty message, closing connection")
      connection.close
    else
      @log.debug("(#{init_timestamp}) Message received: #{msg}")
      post_to_server(msg, init_timestamp)
    end
  end

  def extract_message(connection, init_timestamp)
    @log.debug("(#{init_timestamp}) extract_message begin")

    return nil if connection.closed?

    # We tell Ruby to use a dollar sign as the custom message terminator character
    connection.gets('$')
  end

  def empty_string?(str, init_timestamp)
    @log.debug("(#{init_timestamp}) str: #{str}")
    str.nil? || str.strip.empty?
  end

  def post_to_server(msg, init_timestamp)
    # Create the request object to use
    uri, request = generate_http_obj(msg, init_timestamp)

    # Set the options
    req_options = { use_ssl: uri.scheme == 'https' }

    begin
      # Make the call
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      handle_response(response, init_timestamp)
    rescue StandardError => e
      @log.debug(e.message)
    end
  end

  def generate_http_obj(msg, init_timestamp)
    uri = generate_uri
    @log.debug("(#{init_timestamp}) URL: #{uri}")

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json; charset=utf-8'
    request.body = data_prep(msg)
    @log.debug("(#{init_timestamp}) Body: #{request.body}")

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
      'prod': 'https://api.pumptrakr.com'
    }
    domain_hash[@environment.to_sym]
  end

  def determine_path
    case @model
    when 'GV600'
      '/api/v2/webhooks/modules/gv600_messages'
    when 'GV350'
      '/api/v2/webhooks/modules/gv350_messages'
    else
      '/api/v2/webhooks/modules/tcp_proxy'
    end
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
    @log.debug "(#{init_timestamp}) Successfully posted to PumpTrakr"
    @log.debug "(#{init_timestamp}) Code: #{response.code}"
    @log.debug "(#{init_timestamp}) Body: #{response.body}"
  end

  def handle_error(response, init_timestamp)
    # Error!
    @log.debug "(#{init_timestamp}) Unsuccessfully posted to PumpTrakr"
    @log.debug "(#{init_timestamp}) Code: #{response.code}"
    @log.debug "(#{init_timestamp}) Body: #{response.body}"
  end
end
