# frozen_string_literal: true

require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'logger'
require_relative 'proxy_server'

def arg_checks
  # Argument checks
  if ARGV.length > 3
    puts 'Too many arguments, must pass in port, environment ("local", "staging", "prod"), and module type (350, 600)'
    exit
  end

  return unless ARGV.length.positive?

  environment = ARGV[1]
  unless %w[local staging prod].include?(environment)
    puts "#{environment} is not a valid environment. The only valid environments are local, staging, prod."
    exit
  end

  module_model = ARGV[2].to_i
  unless [600, 350, 3333].include?(module_model)
    puts "#{module_model} is not a valid module type. The only valid module types are: 350, 600, 3333"
    exit
  end
end

def extract_port
  ARGV[0]
end

def extract_environment
  ARGV[1]
end

def extract_module_type
  ARGV[2]&.to_i
end

# Run our argument checks
arg_checks

# Extract our arguments
server_port = extract_port
environment = extract_environment
module_model = extract_module_type

server = ProxyServer.new(server_port, environment, module_model)
server.start
