# TODO: Write documentation for `CrystalFTP`

require "socket"
require "./Commands.cr"
require "./User.cr"
require "./Config.cr"

module CrystalFTP
  include Config

  class FTPServer
    getter port
    getter root

    include Commands

    def initialize(@port = 8000, root = '.')
      @server = TCPServer.new("0.0.0.0", port.to_i)
      @root = File.expand_path(root)
    end

    def start
      spawn do
        puts "FTP server, rooted at #{@root}, now listening on port #{@port}..."
        loop &->accept_client
      end
    end

    private def accept_client()
      socket = @server.accept?
      return if socket.nil?
      handle_client(User::UserData.new(socket, @root))
    end

    private def handle_client(user)
      spawn do
        welcome user
        while !user.socket.closed? && (line = user.socket.gets)
          handle_request(user, line.rstrip)
        end
      end
    end

    private def welcome(user)
      FTPServer.reply(user.socket, 220, "Welcome on crystalFTP server!")
    end

    private def parse_command(message)
      args = message.split(" ")
      command = args.shift
      puts "Command: #{command}, args: #{args}"
      {command, args}
    end

    private def handle_request(user, message)
      command, args = parse_command message
      if !user.is_authentified && !ANONYM_COMMANDS.includes? command
        FTPServer.reply(user.socket, 530, "Please login with USER and PASS.")
        return
      end
      callback = COMMANDS[command.downcase]?
      callback ||= COMMANDS["unknown"]
      callback.call(user, args)
    end

    def self.reply(socket, code, message)
      socket << code << " " << message << "\r\n"
    end

  end
end
