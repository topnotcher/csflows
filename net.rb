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
	mask = (0xffffffff - (2**(32-prefix)-1)).to_i 

	ip_start = ip&mask
	ip_end = ip_start + 2**(32-prefix)-1

	return {
		ip_max: ip_end,
		ip_min: ip_start
	}
end
