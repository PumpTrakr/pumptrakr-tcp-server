class Question
  attr_accessor :prompt, :answer, :env
  require 'socket'
  require 'net/http'
  require 'uri'
  require 'json'
  require 'logger'
  require_relative 'proxy_test_msg'
  require_relative 'command_line_checks'

  def initialize(prompt, answer)
    @prompt = prompt
    @answer = answer

  end
end

@port = 4444
@module_model = ''
@environment = ''
@command = ''
p1 = "Which Environment is the module on? \n\n1. Production \n2. Staging \n3. Exit"
p2 = "What is the Model? \n\n1. GV600 \n2. GV620 \n3. GV350 \n4. Start Over \n4. Exit"
p3 = "What message would you like to masquerade as the device, or: \n1. Start Over \n2. Exit"
p4 = " WARNING: This will send a message from the TCP server as the device, and can not be undone, are you sure? \n\n1. Yes  \n2. Start Over \n3. Exit"

@env_questions = [
  Question.new(p1, ''),
]

@module_model_questions = [Question.new(p2, '')
]

@command_question = [Question.new(p3, '')]

@confirm_question = [Question.new(p4, '')]

def render_ascii_art
  banner = File.read("ascii-art.txt")
  puts banner + "\n"
  run_cred(@env_questions)
end

def run_confirm(confirm_question)
  confirm_question.each do |question|
    puts question.prompt
    answer = gets.chomp
    case answer
    when '1'
      server = ProxyTestMsg.new(server_port = @port, environment = @environment, module_model = @module_model, msg = @command)
      server.post_to_server(msg = @command, Time.now)
      puts " \n\n
      ==============================================
        Message sent, check admin panel for status
      ----------------------------------------------

                     NEW SESSION STARTED

      ----------------------------------------------\n\n"

      run_cred(@env_questions)
    when '2'
      puts 'Message not sent, starting over'
      run_cred(@env_questions)
    when '3'
      puts 'Message not sent, exiting'
    else
      puts 'Key stroke error, please try again valid responses are 1, 2 or 3'
      run_confirm(@confirm_question)
    end
  end
end

def run_model(model_questions)
  model_questions.each do |question|
    puts question.prompt
    answer = gets.chomp
    case answer
    when '1'
      @module_model = "GV600"
      puts "\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: #{@module_model}
         |       Message to send: < not yet set >
         |
         |
          -------------------------------------------------------------------------\n"
      run_command(@command_question)
    when '2'
      @module_model = "GV600"
      puts "\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: #{@module_model}
         |       Message to send: < not yet set >
         |
         |
          -------------------------------------------------------------------------\n"
      run_command(@command_question)
    when '3'
      @module_model = "GV350"
      puts "\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: #{@module_model}
         |       Message to send: < not yet set >
         |
         |
          -------------------------------------------------------------------------\n"
      run_command(@command_question)
    when '4'
      puts 'starting over'
      run_cred(@env_questions)
    when '5'
      puts 'exiting -- bye'
      exit
    else
      puts 'key stroke error, please try again valid responses are 1, 2, 3 or 4'
      run_model(@module_model_questions)
    end
  end
end

def run_command(command_question)
  command_question.each do |question|
    puts question.prompt
    answer = gets.chomp
    case answer
    when '1'
      puts 'starting over'
      run_cred(@env_questions)
    when '2'
      puts 'exiting -- bye'
      exit
    else
      if answer.length > 20
        @command = answer
        puts "\n\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: #{@module_model}
         |       Message to send: #{@command}
         |       WARNING: Once the message is sent it can not be undone
         |
          -------------------------------------------------------------------------\n"
        run_confirm(@confirm_question)
      else
        puts "\n
          ===========================================
                  !!!!!! == ERROR == !!!!!!
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: #{@module_model}
         |       Message: #{answer}
         |       {ERROR: Message must be greater than 20 characters - Exiting}
         |
          -------------------------------------------------------------------------\n"
        exit
      end
    end
  end
end

def run_cred(env_questions)

  env_questions.each do |question|
    puts question.prompt
    answer = gets.chomp
    case answer
    when '1'
      @environment = 'production'
      puts "\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: < not yet set >
         |       Message to send: < not yet set >
         |
         |
          -------------------------------------------------------------------------\n"
      run_model(@module_model_questions)
    when '2'
      @environment = 'staging'
      puts "\n
          ===========================================
                       MESSAGE INFORMATION
          ===========================================\n
          -------------------------------------------------------------------------
         |
         |       Environment: #{@environment}
         |       Module: < not yet set >
         |       Message to send: < not yet set >
         |
         |
          -------------------------------------------------------------------------\n"
      run_model(@module_model_questions)
    when '3'
      puts 'exiting -- bye'
      exit
    else
      puts 'key stroke error, please try again, valid responses are 1, 2, or 3'
      run_cred(@env_questions)
    end
  end
end

render_ascii_art
