require_relative 'palogs'
require_relative 'syslog'
require 'time'
require 'yaml'

sources = []
config = YAML::load(File.open('samples.yaml'))
config[:sources].each do |source|
	processor_config = source[:processor]
	sources << {
		syslog: SyslogSampler.new('0.0.0.0',source[:port],source[:rate], 512),
		processor: Object::const_get(source[:processor][:class]).new(source[:processor])
	}
 
end
threads = []
sources.each do |source|
	threads << Thread.new do
		while true 
			record = source[:syslog].get
			log = record[0]
			src = record[1][2]

			#slice out facility. 
			log.slice!(0,log.index('>')+1)
			dt = Time.parse(log.slice!(0,15))
			log.lstrip!
			host = log.slice!(0,log.index(' '))
			log.lstrip!

			source[:processor].process(dt,src,log)
		end
	end
end

sleep

#["LOG DATA", ["AF_INET", 33704, "ipaddress", "ipaddress"]]

