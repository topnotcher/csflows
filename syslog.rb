require 'socket'

svr = UDPSocket.new

svr.bind('0.0.0.0',1337)

i = 0
while true do
	data = svr.recvfrom(512)

	process(data) if i == 0

	i += 1
	i = 0 if i == 1000
end
