require_relative 'net'

class DeptData

	def initialize(data_file)
		read_dept_data data_file
	end
	
	def read_dept_data(data_file)

		@dept_data = []
		File.open(data_file) do |fh|
			lines = fh.read.lines
			lines.drop(1)
			data = []

			lines.each do |line|
				data = line.strip.split(',',5)

				dept_info = cidr2range(data[0])
				dept_info[:iso_dept] = data[3]
				dept_info[:iso_desc] = data[4]
				@dept_data << dept_info
			end
		end
	end

	def lookup(ip) 
		ip = ip2n(ip)

		@dept_data.each do |dept|
			return dept if ip <= dept[:ip_max] and ip >= dept[:ip_min]
		end

		return nil
	end

end
