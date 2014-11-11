#!/usr/bin/env ruby

# Command line arguments
require 'optparse'

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: mybb_hook_finder.rb [options]"

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

# Loop through every *.php file in the mybb directory and read it
Dir.glob(options[:mybb_root] + "**/*.php") do |mybb_file|
	File.open(mybb_file, "r") do |file| # Open the file for reading
		line_no = 0
		file_name = mybb_file[options[:mybb_root].length, mybb_file.length - options[:mybb_root].length]
		while !file.eof? # Loop through every line of the file looking for matches - have to do it this way to get the line number
			line = file.readline
			line_no += 1
			if (line =~ /\$plugins->run_hooks\(['|"]([\w ]+)['|"](, ?(\$[\w]+))*\);/) # Does the lien contains a $plugins->run_hooks() call? If so, we've found a hook!
				hooks[$1] = [$3, mybb_file, line_no]
				file_hooks[file_name].push([$1, $3, line_no])
			end
		end
	end
end

File.open(options[:output_file], "w+") do |file| # Write the output file!
	file.puts %{<!doctype html>
<html lang="en-GB">
	<head>
		<title>MyBB Hooks</title>
		<style>
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
		</style>
	</head>
	<body>
		<h1>MyBB Hooks</h1>
		<table>}

	if (options[:group_output])
		i = 0
		file_hooks.each_pair do |key, value|
			file.puts %{<tr class="file">
					<th colspan="3" class="tcat"><strong>File: </strong> #{key}</th>
				</tr>
				<tr class="heading">
					<td>Hook</td>
					<td>Params</td>
					<td>Line</td>
				</tr>}

			file_hooks[key].each do |subVal|
				file.puts %{<tr>
						<td>#{subVal[0]}</td>
						<td>#{subVal[1]}</td>
						<td>#{subVal[2]}</td>
					</tr>}
			end

			i += 1
		end
	else
		hooks.each do |key, value|
			file.puts %{<tr>
					<td><strong>Hook: </strong>#{key}</td>
					<td>}

			if (!value[0].empty?)
				file.puts "<strong>Params: </strong>#{value[0]}"
			end

			file.puts %{</td>
					<td><strong>File / Line </strong>#{value[1]} / #{value[2]}</td>
				</tr>}

		end
	end

	file.puts %{</table>
	</body>
</html>}
end

system("start " + options[:output_file])
