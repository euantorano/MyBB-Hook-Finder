#!/usr/bin/env ruby

# Command line arguments
require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: mybbhooks.rb [options]"

	options[:mybb_root] = ""
	opts.on( '-p', '--path PATH', 'Specify a path to the MyBB root. Defaults to current directory.' ) do |mybb_path|
		options[:mybb_root] = mybb_path.strip.chomp("\\").chomp("/") + "/"
	end

	options[:output_file] = "output.html"
	opts.on( '-o', '--output FILE', 'Specify an output file. Defaults to output.html.' ) do |output_file|
		options[:output_file] = output_file
	end

	options[:group_output] = true
	opts.on( '-n', '--nogroup', 'Don\'t group hooks by file.' ) do
		options[:group_output] = false
	end

	opts.on( '-h', '--help', 'Display this help screen' ) do
		puts opts
		exit
	end
end.parse!

# Hook parsing
hooks = Hash.new
file_hooks = Hash.new{|hash, key| hash[key] = Array.new}

Dir.glob(options[:mybb_root] + "**/*.php") do |mybb_file|
	file = File.open(mybb_file, "r")
	line_no = 0
	file_name = mybb_file[options[:mybb_root].length, mybb_file.length - options[:mybb_root].length]
	while !file.eof?
		line = file.readline
		line_no += 1
		if (line =~ /\$plugins\->run_hooks\(((["']?)([a-zA-Z\-_0-9]*)(["']?))([,]?)([ \$a-zA-Z0-9]*?)\);/i)
			hooks[$3.strip] = [$6.strip, mybb_file, line_no]
			file_hooks[file_name].push([$3.strip, $6.strip, line_no])
		end
	end
end

fileOutput = File.new(options[:output_file], "w+")
fileOutput.puts "<!doctype html>"
fileOutput.puts "<html lang=\"en-GB\">"
fileOutput.puts "	<head>"
fileOutput.puts "		<title>MyBB Hooks</title>"
fileOutput.puts "		<style>
			* {
				margin: 0;
				padding: 0;
			}

			body {
				padding: 4px;
				overflow-y: scroll;
				font-family: Tahoma, Verdana, Segoe, sans-serif;
			}

			table {
				margin: 8px 4px 4px;
				width: 100%;
				border: 1px solid rgba(0, 0, 0, 0.2);
			}

			td, th {
				padding: 4px;
				border-bottom: 1px solid rgba(0, 0, 0, 0.15);
			}

			tbody tr:last-child td {
				border-bottom: 0;
			}

			tr.file th {
				background: rgba(0, 0, 0, 0.1);
			}

			tr.heading td {
				font-weight: bold;
			}
		</style>"
fileOutput.puts "	</head>"
fileOutput.puts "	<body>"
fileOutput.puts "		<h1>MyBB Hooks</h1>"
fileOutput.puts "		<table>"

if (options[:group_output])
	i = 0
	file_hooks.each_pair do |key, value|
		fileOutput.puts "			<thead>"
		fileOutput.puts "				<tr class=\"file\">"
		fileOutput.puts "					<th colspan=\"3\" class=\"tcat\"><strong>File: </strong> #{key}</th>"
		fileOutput.puts "				</tr>"
		fileOutput.puts "				<tr class=\"heading\">"
		fileOutput.puts "					<td>Hook</td>"
		fileOutput.puts "					<td>Params</td>"
		fileOutput.puts "					<td>Line</td>"
		fileOutput.puts "				</tr>"
		fileOutput.puts "			</thead>"
		fileOutput.puts "			<tbody id=\"hook_group_#{i}\">"
		file_hooks[key].each do |subVal|
			fileOutput.puts "				<tr>"
			fileOutput.puts "					<td>#{subVal[0]}</td>"
			fileOutput.puts "					<td>#{subVal[1]}</td>"
			fileOutput.puts "					<td>#{subVal[2]}</td>"
			fileOutput.puts "				</tr>"
		end
		fileOutput.puts "			</tbody>"
		i += 1
	end
else
	hooks.each do |key, value|
		fileOutput.puts "				<tr>"
		fileOutput.puts "					<td><strong>Hook: </strong>#{key}</td>"
		if (!value[0].empty?)
			fileOutput.puts "			<td><strong>Params: </strong>#{value[0]}</td>"
		else
			fileOutput.puts "			<td></td>"
		end
		fileOutput.puts "					<td><strong>File / Line </strong>#{value[1]} / #{value[2]}</td>"
		fileOutput.puts "				</tr>"
	end
end

fileOutput.puts "			</tbody>"
fileOutput.puts "		</table>"
fileOutput.puts "	</body>"
fileOutput.puts "</html>"
fileOutput.close

system("start " + options[:output_file])
