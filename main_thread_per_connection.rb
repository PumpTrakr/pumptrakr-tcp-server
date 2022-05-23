# frozen_string_literal: true

require 'async'
require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'logger'
require 'timers'
require_relative 'proxy_server'
require_relative 'command_line_checks'

# Run our argument checks
arg_checks

# Extract our arguments
server_port = extract_port
environment = extract_environment
module_model = extract_module_type

module TCP
  Connection = Struct.new(:client) do
    CRLF = '$'

    def gets
      client.gets(CRLF)
    end

    def respond(message)
      client.write(message)
      client.write(CRLF)
    end

    def close
      client.close
    end
  end

  class ThreadPerConnection
    def initialize(port, environment, module_model)
      @port = port
      @environment = environment
      @model = module_model
      @control_socket = TCPServer.new(@port)
      trap(:INT) { exit }
    end

    def run
      Thread.abort_on_exception = false

      loop do
        conn = Connection.new(@control_socket.accept)

        Thread.new do
          # conn.respond '220 OHAI'
          handler = TCP::MessageHandler.new(conn, @environment, @model)
          last_message = Time.now.utc

          loop do
            puts 'now:'
            now = Time.now.utc
            puts now

            time_since = now - last_message
            puts time_since.to_s

            if (time_since * 10_000) < 5
              request = conn.gets
              puts request
              if request
                puts request
                conn.respond handler.handle(request)
                # reset last message to now
                last_message = Time.now.utc
              else
                conn.close
                break
              end
            else
              'past 5 seconds'
              conn.close
              break
            end
          end
        end
      end
    end
  end

  class MessageHandler
    def initialize(connection, environment, module_model)
      @connection = connection
      @environment = environment
      @model = module_model
    end

    def handle(message)
      # Create the request object to use
      uri = generate_uri
      request = generate_request(uri, message)

      # Set the options
      req_options = { use_ssl: uri.scheme == 'https' }

      # Make the call
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      handle_response(response)
    end

    private

    def generate_request(uri, message)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json; charset=utf-8'
      request.body = data_prep(message)

      request
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

    def handle_response(response)
      # Check the status code
      case response.code.to_i
      when 200, 201, 204
        # If we want to do anything on success
        true
      else
        false
      end
    end
  end
end

server = TCP::ThreadPerConnection.new(server_port, environment, module_model)
server.run
