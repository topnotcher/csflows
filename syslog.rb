require 'socket'


class SyslogSampler

	def initialize(ip,port,samplerate, max=512)
		@sock = UDPSocket.new
		@sock.bind(ip,port)
		@max = max
		@rate = samplerate
		@counters = {}
	end
	
	def get
		while true do
			data = @sock.recvfrom(@max)
			src = data[1][2]

			@counters[src] ||= 0
			@counters[src] += 1
			@counters[src] = 0 if @counters[src] >= @rate

			return data if @counters[src] == 0

		end
	end
end
