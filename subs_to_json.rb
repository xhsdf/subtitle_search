#!/usr/bin/ruby

require 'pathname'

input_folder = ARGV[0]
series = ARGV[1]
remove_clean = ARGV.include? '--remove-clean' # remove screenshots without subtitles in them
compact = ARGV.include? '--compact' # keep only 1 screenshot per line


def main(input_folder, series, remove_clean, compact)
	sws = {}
	File.open("#{input_folder}/dialogue.json", 'w') do |output| 
		output.puts "{"
		output.puts " \"series\": \"#{series}\","
		output.puts " \"episodes\": ["
		Pathname.new(input_folder).children.select do |folder| folder.directory? end.sort.each_with_index do |folder, i|
			output.print "      ," if i > 0
			output.puts " {"
			output.puts "  \"name\": \"#{folder.basename}\","
			output.puts "  \"languages\": ["
			Pathname.new(folder).children.select do |file| file.to_s.end_with? ".ass" end.each_with_index do |file, u|
				lang = file.basename.to_s.gsub(".ass", "")
				sws = []
				output.print "      ," if u > 0
				output.puts "  {"
				output.puts "   \"lang\": \"#{lang}\","
				output.puts "   \"dialogues\": ["
				File.readlines(file).select do |line| line.start_with? "Dialogue: " end.each_with_index do |line, o|
					output.print "      ," if o > 0
					start_seconds, end_seconds, text = parse_line(line)
					if compact
						sws << (((start_seconds + 1) + end_seconds) / 2)
					elsif remove_clean
						for i in (start_seconds + 1)..end_seconds
							sws << i
						end
					end
					output.puts "   { \"s\": \"#{start_seconds}\", \"e\": \"#{end_seconds}\", \"t\": \"#{text.strip.gsub("\\", "\\\\\\\\").gsub('"', '\"')}\" }"
				end
				output.puts "   ]"
				output.puts "  }"

				if remove_clean or compact
					Pathname.new("#{folder}/#{lang}").children.select do |screen| screen.file? and screen.basename.to_s =~ /^\d+\.jpg$/ end.each do |screen|
						u = screen.basename.to_s.gsub('.jpg', '').to_i
						unless sws.include? u
							screen.unlink
						end
					end
				end
			end
			output.puts "  ]"
			output.puts " }"
		end

		output.puts " ]"
		output.puts "}"
	end

end


def timestamp_to_seconds(timestamp)
	timestamp.gsub!(/\..*$/, '')
	h, m ,s = timestamp.split(':')
	return (h.to_i * 3600) + (m.to_i * 60) + s.to_i
end


def parse_line(line)
	splits = line.split ','
	startTime = splits[1]
	endTime = splits[2]
	text = splits[9..-1].join(',').gsub(/\{[^\}]+\}/, '')
	return timestamp_to_seconds(startTime), timestamp_to_seconds(endTime), text
end



main(input_folder, series, remove_clean, compact)
