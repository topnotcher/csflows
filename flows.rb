require_relative 'net'

file = 'log.csv'

$result = {}


def analyze(data)
#	puts data
	sip = data['Source address']

	$result[sip] = 0 unless $result.include? sip

	$result[sip] += data['pkts_sent'].to_i + data['pkts_received'].to_i
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



def process_flow_syslog(line)
	exclude_cols = ['domain','serial','config_version', 'nat_source_ip', 'nat_destination_ip', 'source_user', 'destination_user', 'virtual_system', 'inbound_interface', 'outbound_interface', 'session_id']

	cols = %w{
		domain receive_time serial type type config_version generate_time source_address 
		destination_address nat_source_ip nat_destination_ip rule source_user destination_user 
		application virtual_system source_zone destination_zone inbound_interface outbound_interface 
		log_action time_logged session_id repeat_count source_port destination_port nat_source_port 
		nat_destination_port flags ip_protocol action bytes bytes_sent bytes_received packets 
		start_time elapsed_seconds category padding seqno actionflags source_country destination_country 
		cpadding pkts_sent pkts_received
	}
 
	new_cols = cols-exclude_cols
	new_cols += ['iso_dept','iso_desc']

	new = File.open('new.csv','a')

#	new.write(new_cols.join(','))
#	new.write("\n")

	data = line.strip.split(',')
	
	new_data = []
	src_ip_idx = nil
	dest_ip_idx = nil
	# drop cols
	(0..data.size-1).each do |i|
		new_data <<= data[i] unless exclude_cols.include? cols[i] 

		if cols[i] == 'destination_address'
			dest_ip_idx = i
		end

		if cols[i] == 'source_address'
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
	new.close
end
