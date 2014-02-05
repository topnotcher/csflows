require_relative 'net'
require_relative 'dept_data'


$dept_data = DeptData.new('sc_deployment.csv')

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


	dept = $dept_data.lookup(data[src_ip_idx])
	dept = $dept_data.lookup(data[dest_ip_idx]) unless dept

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
