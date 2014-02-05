require_relative 'flows'
require_relative 'syslog'
require 'time'

syslog = SyslogSampler.new('0.0.0.0',1337,1000, 512)

while true do
	record = syslog.get
	log = record[0]

	#slice out facility. 
	log.slice!(0,log.index('>')+1)
	dt = Time.parse(log.slice!(0,15))
	log.lstrip!
	host = log.slice!(0,log.index(' '))
	log.lstrip!

	process_flow_syslog(log)

end

#["LOG DATA", ["AF_INET", 33704, "ipaddress", "ipaddress"]]
