# frozen_string_literal: true

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

  module_model = ARGV[2]
  unless %w[GV600 GV350 ANY].include?(module_model)
    puts "#{module_model} is not a valid module type. The only valid module types are: GV350, GV600, ANY"
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
  ARGV[2]
end
