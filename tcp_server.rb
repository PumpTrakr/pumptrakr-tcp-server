# frozen_string_literal: true

require 'socket'
require 'net/http'
require 'uri'
require 'json'

def arg_checks
  # Argument checks
  if ARGV.length > 1
    puts 'Too many arguments, only accepted argument is the module type (350, 600)'
    exit
  end

  return unless ARGV.length.positive?

  module_model = ARGV[0].to_i

  unless [600, 350].include?(module_model)
    puts "#{module_model} is not a valid module type. The only valid module types are: 350, 600"
    exit
  end
end

def extract_arg
  ARGV[0]&.to_i
end

# Run our argument checks
arg_checks

# Extract our argument
module_model = extract_arg

# Define our ProxyServer
class ProxyServer
  def initialize(port, module_model)
    @model = module_model
    @server = TCPServer.new(port)
    puts "Listening on port #{port}\nReceived messages will be delivered to: \n#{generate_uri}"
  end

  def start
    Socket.accept_loop(@server) do |connection|
      Thread.new do
        loop do
          handle(connection)
        end
      end
    end
  end

  private

  def handle(connection)
    msg = connection&.gets
    puts msg
    if empty_string?(msg)
      connection.close
    else
      post_to_server(msg)
    end
  end

  def empty_string?(str)
    str.nil? || str.strip.empty?
  end

  def post_to_server(msg)
    # Create the request object to use
    uri, request = generate_http_obj(msg)

    # Set the options
    req_options = {
      use_ssl: uri.scheme == 'https'
    }

    # Make the call
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    handle_response(response)
  end

  def generate_http_obj(msg)
    uri = generate_uri

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json; charset=utf-8'
    request.body = data_prep(msg)

    [uri, request]
  end

  def generate_uri
    base = 'https://api.pumptrakr.com'

    case @model
    when 600
      path600 = '/api/v2/webhooks/modules/gv600_messages'
      url = "#{base}#{path600}"
    when 350
      path350 = '/api/v2/webhooks/modules/gv350_messages'
      url = "#{base}#{path350}"
    else
      orig_path = '/api/v2/webhooks/modules/tcp_proxy'
      url = "#{base}#{orig_path}"
    end
    URI.parse(url)
  end

  def data_prep(msg)
    { message: msg }.to_json
  end

  def handle_response(response)
    # Check the status code
    if %w([200 201 204]).include? response.code
      # Everything worked
      puts response.body
    else
      # Error!
      puts "#{response.code} #{response.message}"
    end
  end
end

server = ProxyServer.new(3333, module_model)
server.start
