require_relative 'flows'
require_relative 'syslog'
require 'time'

syslog = SyslogSampler.new('0.0.0.0',1337,100, 512)
processor = PAFlowProcessor.new


while true do
	record = syslog.get
	log = record[0]
	src = record[1][2]

	#slice out facility. 
	log.slice!(0,log.index('>')+1)
	dt = Time.parse(log.slice!(0,15))
	log.lstrip!
	host = log.slice!(0,log.index(' '))
	log.lstrip!

	processor.process(dt,src,log)

end

#["LOG DATA", ["AF_INET", 33704, "ipaddress", "ipaddress"]]

