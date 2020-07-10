require 'socket'
require 'net/http'
require 'uri'
require 'JSON'
@server = TCPServer.new 3333

def main
  # Servers run forever
  loop do
    Thread.start(@server.accept) do |client|
      line = client.recv(1000).strip # Read lines from the socket
      puts line
      post_to_server line unless line == '' # method to handle messages from the socket
      client.close # Disconnect from the client
    end
  end
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

  puts response 
  handle_response(response)
end

def generate_http_obj(msg)
  # domain
  host = 'pumptrakr-api.herokuapp.com'
  path = '/api/v1/webhooks/tcp_proxy'

  uri = URI.parse("https://#{host}/#{path}")

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
  # puts response&.body
  # puts response&.message

  # Check the status code
  if %w([200 201 204]).include? response.code
    # Everything worked
    puts response.body
  else
    # Error!
    puts "#{response.code} #{response.message}"
  end
end

main
