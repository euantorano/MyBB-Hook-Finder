#!/usr/bin/env ruby

hooks = Hash.new

Dir.glob("**/*.php") do |mybb_file|
	file = File.open(mybb_file, "r")
	line_no = 0
	while !file.eof?
		line = file.readline
		line_no += 1
		if (line =~ /\$plugins\->run_hooks\(((["']?)([a-zA-Z\-_0-9]*)(["']?))([,]?)([ \$a-zA-Z0-9]*?)\);/i)
			hooks[$3.strip] = [$6.strip, mybb_file, line_no]
		end
	end
end

fileOutput = File.new("output.html", "w+")
fileOutput.puts "<!doctype html>"
fileOutput.puts "<html lang=\"en-GB\">"
fileOutput.puts "	<head>"
fileOutput.puts "		<title>MyBB Hooks</title>"
fileOutput.puts "	</head>"
fileOutput.puts "	<body>"
fileOutput.puts "		<h1>MyBB Hooks</h1>"
fileOutput.puts "		<table>"
fileOutput.puts "			<thead>"
fileOutput.puts "				<tr>"
fileOutput.puts "					<th>Hook Name</th>"
fileOutput.puts "					<th>Arguments</th>"
fileOutput.puts "					<th>File Name / Line Number</th>"
fileOutput.puts "				</tr>"
fileOutput.puts "			</thead>"
fileOutput.puts "			<tbody>"

hooks.each do |key, value|
	fileOutput.puts "				<tr>"
	fileOutput.puts "					<td><strong>#{key}</strong></td>"
	fileOutput.puts "					<td>#{value[0]}</td>"
	fileOutput.puts "					<td>#{value[1]} / #{value[2]}</td>"
	fileOutput.puts "				</tr>"
end

fileOutput.puts "			</tbody>"
fileOutput.puts "		</table>"
fileOutput.puts "	</body>"
fileOutput.puts "</html>"
fileOutput.close

system("start output.html")
