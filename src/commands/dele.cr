def rm_r(path : String) : Nil
  if Dir.exists?(path) && !File.symlink?(path)
    Dir.each_child(path) do |entry|
      src = File.join(path, entry)
      rm_r(src)
    end
    Dir.rmdir(path)
  else
    File.delete(path)
  end
end

def dele(user, args)
  return FTPServer.reply(user.socket, 550, "Failed to delete file.") if args.size != 1
  path = File.expand_path(args[0], user.working_directory)
  return FTPServer.reply(user.socket, 550, "Failed to delete file.") if !File.exists? args[0]
  user.working_directory = File.expand_path("..", user.working_directory) if path == user.working_directory
  rm_r path
  FTPServer.reply(user.socket, 250, "File successfully deleted.")
rescue e
  puts e.message
  FTPServer.reply(user.socket, 550, "Failed to delete file.")
end