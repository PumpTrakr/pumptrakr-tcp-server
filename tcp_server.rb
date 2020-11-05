# frozen_string_literal: true

require 'socket'
require 'net/http'
require 'uri'
require 'json'

class ProxyServer
  def initialize(port)
    @server = TCPServer.new(port)
    puts "Listening on port #{port}"
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
    request = connection.gets
    # connection.close if request.nil?
    puts(request)
    post_to_server(request) unless empty_string?(request)
  end

  def empty_string?(str)
    str.strip.empty?
  end

  def post_to_server(msg)
    puts msg
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
    # domain
    protocol = 'https://'
    host = 'api.pumptrakr.com'
    path = '/api/v1/webhooks/tcp_proxy'

    uri = URI.parse("#{protocol}#{host}#{path}")

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json; charset=utf-8'
    request.body = data_prep(msg)

    [uri, request]
  end

  def data_prep(msg)
    { message: msg }.to_json
  end

  def handle_response(response)
    puts response&.code

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

server = ProxyServer.new(3333)
server.start
