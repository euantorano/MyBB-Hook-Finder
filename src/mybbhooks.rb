#!/usr/bin/env ruby

hooks = Hash.new
line_no = 0
mybb_core_location = ""

Dir.glob("**/*.php") do |mybb_file|
	file = File.open(mybb_file, "r")
	line_no = 0
	while !file.eof?
		line = file.readline
		line_no = line_no + 1
		if (line =~ /\$plugins\->run_hooks\(((["']?)([a-zA-Z\-_0-9]*)(["']?))([,]?)([ \$a-zA-Z0-9]*?)\);/i)
			hooks[$3.strip] = [$6.strip, mybb_file, line_no]
		end
	end
end

hooks.each do |key, value|
	puts "Hook name: #{key}\n"
	puts "Arguments: #{value[0]}\n"
	puts "File\\Line: #{value[1]}\\#{value[2]}"
	puts "\n"
end

puts "Press ENTER to exit"
command = gets
