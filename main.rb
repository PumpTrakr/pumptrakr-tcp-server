# frozen_string_literal: true

require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'logger'
require_relative 'proxy_server'
require_relative 'command_line_checks'

# Run our argument checks
arg_checks

# Extract our arguments
server_port = extract_port
environment = extract_environment
module_model = extract_module_type

server = ProxyServer.new(server_port, environment, module_model)
server.start
