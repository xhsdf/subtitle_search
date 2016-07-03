#!/usr/bin/ruby

require 'pathname'
require 'json'

input_folder = ARGV[0]
series = ARGV[1]
remove_clean = ARGV.include? '--remove-clean' # remove screenshots without subtitles in them
compact = ARGV.include? '--compact' # keep only 1 screenshot per line


def main(input_folder, series, remove_clean, compact)
	File.open("#{input_folder}/dialogue.json", 'w') do |output|
		sws = {}
		s = { "series" => series, "episodes" => [] }
		Pathname.new(input_folder).children.select do |folder| folder.directory? end.sort.each do |folder|
			e = { "name" => folder.basename, "languages" => [] }
			Pathname.new(folder).children.select do |file| file.to_s.end_with? ".ass" end.each do |file|
				l = { "lang" => file.basename.to_s.gsub(".ass", ""), "dialogues" => [] }
				sws = []
				File.readlines(file).select do |line| line.start_with? "Dialogue: " end.each do |line|
					start_seconds, end_seconds, text = parse_line(line)
					if compact
						sws << (((start_seconds + 1) + end_seconds) / 2)
					elsif remove_clean
						for i in (start_seconds + 1)..end_seconds
							sws << i
						end
					end
					l["dialogues"] << ({ "s" => start_seconds, "e" => end_seconds, "t" => text.gsub(/[\r\n]/, '')})
				end

				if remove_clean or compact
					Pathname.new("#{folder}/#{l['lang']}").children.select do |screen| screen.file? and screen.basename.to_s =~ /^\d+\.jpg$/ end.each do |screen|
						u = screen.basename.to_s.gsub('.jpg', '').to_i
						unless sws.include? u
							screen.unlink
						end
					end
				end
				e["languages"] << l
			end
			s["episodes"] << e
		end
		output.write s.to_json
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
