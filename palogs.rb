require_relative 'net'
require_relative 'dept_data'



class PALogProcessor
	def initialize(config)
		@cols = config[:cols]
		@exclude_cols = config[:exclude_cols]
		@name = config[:name]

		@new_cols = @cols - @exclude_cols
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

		@filenames[src] = '%s-%s-%s.csv' % [@name,src,@dates[src]]
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
			new_data <<= data[i] unless @exclude_cols.include? @cols[i] 

			if @cols[i] == 'destination_address'
				dest_ip_idx = i
			end

			if @cols[i] == 'source_address'
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
