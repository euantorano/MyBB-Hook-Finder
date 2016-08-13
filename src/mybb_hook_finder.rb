#!/usr/bin/env ruby

# Command line arguments
require 'optparse'

if RUBY_VERSION =~ /1.9/ # assuming you're running Ruby ~1.9
	Encoding.default_external = Encoding::UTF_8
	Encoding.default_internal = Encoding::UTF_8
end

options = {}
OptionParser.new do |opts|
	opts.banner = "Usage: mybb_hook_finder.rb [options]"

	options[:mybb_root] = ""
	opts.on( '-p', '--path PATH', 'Specify a path to the MyBB root. Defaults to current directory.' ) do |mybb_path|
		options[:mybb_root] = mybb_path.strip.chomp("\\").chomp("/") + "/"
	end

	options[:output_file] = "output.md"
	opts.on( '-o', '--output FILE', 'Specify an output file. Defaults to output.md.' ) do |output_file|
		options[:output_file] = output_file
	end

	options[:input_file] = ""
	opts.on( '-i', '--input FILE', 'Specify a file to prepend to the Markdown output.' ) do |input_file|
		options[:input_file] = input_file
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
			if (line =~ /\$plugins->run_hooks\(['|"]([\w ]+)['|"](, ?(\$[\w]+))*\);/)
				hooks[$1] = [$3, mybb_file, line_no]
				file_hooks[file_name].push([$1, $3, line_no])
			end
		end
	end
end

mybb_version = ""
mybb_version_code = ""
File.open(options[:mybb_root] + 'inc/class_core.php') do |file|
	has_version = false
	has_version_code = false
	while !file.eof? # Loop through every line of the file looking for matches - have to do it this way to get the line number
		line = file.readline
		if (line =~ /\$version = "([0-9]+\.[0-9]+\.[0-9]+)";/)
			mybb_version = $1
			has_version = true
		end
		if (line =~ /\$version_code = ([0-9]+);/)
			mybb_version_code = $1
			has_version_code = true
		end
		if (has_version && has_version_code)
			break
		end
	end
end

version_note = ""
if (mybb_version != "")
	version_note = " on MyBB " + mybb_version
end

mybb_tag = "feature"
if (mybb_version_code != "")
	mybb_tag = "mybb_" + mybb_version_code
end

if (options[:output_file].end_with? ".md")
	File.open(options[:output_file], "w+") do |file| # Write the output file
		# If we have an input file prepend it to our output
		if (!(options[:input_file].nil? || options[:input_file].empty?))
			File.open(options[:input_file]) do |infile|
				while !infile.eof?
					file.puts infile.readline
				end
			end
		end

		file.puts %{# MyBB Hooks
The following list was generated using [MyBB Hook Finder](https://github.com/euantorano/MyBB-Hook-Finder)#{version_note}. Please note that the line numbers may have subsequently changed.}
		if (options[:group_output])
			i = 0
			file_hooks.each_pair do |key, value|
				file.puts %{

\#\# #{key}

| Hook | Params | Line |
| --- | --- | --- |}

				file_hooks[key].each do |subVal|
					if (!(subVal[1].nil? || subVal[1].empty?))
						params = "`" + subVal[1] + "`"
					else
						params = subVal[1]
					end
					file.puts "| `#{subVal[0]}` | #{params} | [#{subVal[2]}](https://github.com/mybb/mybb/blob/#{mybb_tag}/#{key}\#L#{subVal[2]}) |"
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
					<td><strong>File / Line </strong>#{value[1]} / <a href="https://github.com/mybb/mybb/blob/#{mybb_tag}/#{value[1]}\#L#{value[2]}" title="View on GitHub">#{value[2]}</a></td>
				</tr>}

			end
		end

	end
else
	File.open(options[:output_file], "w+") do |file| # Write the output file
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
						<td><a href="https://github.com/mybb/mybb/blob/#{mybb_tag}/#{key}\#L#{subVal[2]}" title="View on GitHub">#{subVal[2]}</a></td>
					</tr>}
				end

				i += 1
			end
		else
			hooks.each do |key, value|
				file.puts %{<tr>
					<td><strong>Hook: </strong>#{key}</td>
					<td>}

				if (!(value[0].nil? || value[0].empty?))
					file.puts "<strong>Params: </strong>#{value[0]}"
				end

				file.puts %{</td>
					<td><strong>File </strong>#{value[1]}<a href="https://github.com/mybb/mybb/blob/#{mybb_tag}/#{value[1]}\#L#{value[2]}" title="View on GitHub">\##{value[2]}</a></td>
				</tr>}

			end
		end

		file.puts %{</table>
	</body>
</html>}
	end
end

system("start " + options[:output_file])