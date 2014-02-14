require_relative 'net'
require_relative 'dept_data'



class PAFlowProcessor
	@@exclude_cols = %w{
		domain serial config_version nat_source_ip nat_destination_ip source_user destination_user
		virtual_system inbound_interface outbound_interface session_id
	}

	@@cols = %w{
		domain receive_time serial type content_type config_version generate_time source_address 
		destination_address nat_source_ip nat_destination_ip rule source_user destination_user 
		application virtual_system source_zone destination_zone inbound_interface outbound_interface 
		log_action time_logged session_id repeat_count source_port destination_port nat_source_port 
		nat_destination_port flags ip_protocol action bytes bytes_sent bytes_received packets 
		start_time elapsed_seconds category padding seqno actionflags source_country destination_country 
		cpadding pkts_sent pkts_received
	}

	def initialize
		@new_cols = @@cols - @@exclude_cols
		@new_cols += ['iso_dept','iso_desc']
	
		#last date from each source. 
		@dates = {}

		#file handles per source
		@fhs = {}

		#filenames per source
		@filenames = {}

		#@TODO
		@dept_data = DeptData.new('sc_deployment.csv')
	end

	def get_log_fh(dt,src)
		date = dt.to_date
		rotate_date_file(date,src) if @dates[src] != date 
		return @fhs[src]
	end

	def rotate_date_file(date,src)
		@dates[src] = date
		
		# @TODO
		if @fhs[src]
			@fhs[src].close
			#lzma = fork {exec "lzma #{@filenames[src]}"}
			#Process.detach(lzma)
		end

		@filenames[src] = 'flows-%s-%s.csv' % [src,@dates[src]]
		@fhs[src] = File.new(@filenames[src],'a')

		write_log_header @fhs[src]
	end

	def write_log_header(fh)
		fh.write(@new_cols.join(','))
		fh.write("\n")
	end

	def process(dt,src,line)
		fh = get_log_fh(dt,src)

		data = line.strip.split(',')
		
		new_data = []
		src_ip_idx = nil
		dest_ip_idx = nil
		# drop cols
		(0..data.size-1).each do |i|
			new_data <<= data[i] unless @@exclude_cols.include? @@cols[i] 

			if @@cols[i] == 'destination_address'
				dest_ip_idx = i
			end

			if @@cols[i] == 'source_address'
				src_ip_idx = i
			end
		end


		dept = @dept_data.lookup(data[src_ip_idx])
		dept = @dept_data.lookup(data[dest_ip_idx]) unless dept

		if dept 
			new_data <<= dept[:iso_dept]
			new_data <<= dept[:iso_desc]
		else
			new_data += ['','']
		end

		fh.write(new_data.join(','))
		fh.write("\n");
	end end
