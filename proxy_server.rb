# frozen_string_literal: true

require 'logger'

# Define our ProxyServer
class ProxyServer
  def initialize(port, environment, module_model)
    @environment = environment
    @model = module_model
    @server = TCPServer.new(port)
  end

  def start
    Socket.accept_loop(@server) do |connection|
      # Read from the socket until it ends
      # We tell Ruby to use a dollar sign as the custom message terminator character
      msg = connection.gets('$')

      # @log.debug("Extracted message: #{msg}")
      connection.close if msg.nil?

      if msg.nil? || msg.strip.empty?
        # If the message is blank
        connection.close
      else
        # If the message is not blank
        post_to_server(msg)
      end
    end
  end

  private

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
    rescue StandardError => _e
      # @log.debug(e.message)
    end
  end

  def generate_http_obj(msg, _init_timestamp)
    uri = generate_uri

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json; charset=utf-8'
    request.body = data_prep(msg)

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

  def handle_response(response, _init_timestamp)
    # Check the status code
    case response.code.to_i
    when 200, 201, 204
      # If we want to do anything on success
    end
  end
end
