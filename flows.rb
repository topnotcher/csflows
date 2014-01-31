file = 'log.csv'

$result = {}


def analyze(data)
#	puts data
	sip = data['Source address']

	$result[sip] = 0 unless $result.include? sip

	$result[sip] += data['pkts_sent'].to_i + data['pkts_received'].to_i
end

def ip2n(ip)
	n = 0
	shift = 24
	ip.split('.').each do |octet| 
		n += (octet.to_i<<shift)
		shift -= 8
	end
	return n
end

def cidr2range(cidr)
	ip,prefix = cidr.split('/')
	prefix = prefix.to_i
	ip = ip2n(ip)
	mask = 0xffffffff - (2**(32-prefix)-1) 

	ip_start = ip&mask
	ip_end = ip_start + 2**(32-prefix)-1

	return {
		ip_max: ip_end,
		ip_min: ip_start
	}
end


$dept_data = []
File.open('sc_deployment.csv') do |fh|
	lines = fh.read.lines
	lines.drop(1)
	data = []

	lines.each do |line|
		data = line.strip.split(',',5)
	
		dept_info = cidr2range(data[0])
		dept_info[:iso_dept] = data[3]
		dept_info[:iso_desc] = data[4]
		$dept_data << dept_info
	end
end

def get_dept_data_by_ip(ip) 
	ip = ip2n(ip)

	$dept_data.each do |dept|
		return dept if ip <= dept[:ip_max] and ip >= dept[:ip_min]
	end

	return nil
end



File.open(file) do |fh|
	lines = fh.read.lines

	exclude_cols = ['Domain','Serial #','Config Version', 'NAT Source IP', 'NAT Destination IP', 'Source User', 'Destination User', 'Virtual System', 'Inbound Interface', 'Outbound Interface', 'Session ID']

	cols = lines.first.strip.split(',')
	lines = lines.drop(1)
	new_cols = cols-exclude_cols
	new_cols += ['iso_dept','iso_desc']

	new = File.open('new.csv','w')

	new.write(new_cols.join(','))
	new.write("\n")

	lines.each do |line|
		data = line.strip.split(',')
		
		new_data = []
		src_ip_idx = nil
		dest_ip_idx = nil
		# drop cols
		(0..data.size-1).each do |i|
			new_data <<= data[i] unless exclude_cols.include? cols[i] 

			if cols[i] == 'Destination address'
				dest_ip_idx = i
			end

			if cols[i] == 'Source address'
				src_ip_idx = i
			end
		end


		dept = get_dept_data_by_ip(data[src_ip_idx])
		dept = get_dept_data_by_ip(data[dest_ip_idx]) unless dept

		if dept 
			new_data <<= dept[:iso_dept]
			new_data <<= dept[:iso_desc]
		else
			new_data += ['','']
		end

		new.write(new_data.join(','))
		new.write("\n");
		#puts new_data
	end
	new.close
end
