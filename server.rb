require 'webrick'
require 'open-uri'



server = WEBrick::HTTPServer.new( :Port => 4000 , :DocumentRoot => File.expand_path("."))


#get the pahty stahted
server.start




