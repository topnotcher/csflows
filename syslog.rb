require 'socket'


class SyslogSampler

	def initialize(ip,port,samplerate, max=512)
		@sock = UDPSocket.new
		@sock.bind(ip,port)
		@max = max
		@rate = samplerate
	end
	
	def get
		i = 0
		while true do
			data = @sock.recvfrom(@max)

			i += 1
			i = 0 if i >= @rate

			return data if i == 1

		end
	end
end
