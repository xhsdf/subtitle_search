#!/usr/bin/ruby

require 'pathname'
require 'fileutils'
require 'rexml/document'
include REXML

input_folder = ARGV[0]
output_main_dir = ARGV[1]
series = ARGV[2]
clean = ARGV.include? '--clean'
update = ARGV.include? '--update'


def run(file, series, output_main_dir, clean, update)
	filename = file.basename
	puts filename
	output_dir = get_output_dir(output_main_dir, series, filename)
	
	FileUtils.mkdir_p output_dir		
	get_subtitle_tracks(file, clean).each do |index, lang|
		puts "  extracting subtitle track: #{lang}..."
		subtitle_dir = "#{output_dir}/#{lang}"
		if !update and Pathname.new(subtitle_dir).directory?
			puts "    already exists... skipping"
		else
			FileUtils.mkdir_p subtitle_dir
			sub_param = ""
			if lang != 'none'
				system("ffmpeg -i \"#{file}\" -loglevel error -y -map 0:#{index} \"#{subtitle_dir}.ass\"")
				sub_param = ", ass='#{subtitle_dir.gsub("'", "\'\\\\\\\\\\\\'\'")}.ass'" # ¯\_(ツ)_/¯
			end
			puts "  extracting screencaps with subtitle track: #{lang}..."
			system("ffmpeg", "-i", file.to_s, "-loglevel", "error", "-start_number", "0", "-stats", "-vf", "scale=-1:480, fps=1#{sub_param}", "-q:v", "1", "#{subtitle_dir}/%d.jpg")
		end
	end
end


def get_subtitle_tracks(file, clean = false)
	tracks = {}
	ffprobe = `ffprobe -v error -of xml -show_streams -select_streams s "#{file}"`
	xmldoc = Document.new(ffprobe)
	XPath.each(xmldoc, "/ffprobe/streams/stream") do |stream|
		index = stream.attribute('index')
		lang = 'unknown'
		XPath.each(stream, "tag[@key = 'language']/@value") do |lang_attr|
			lang = lang_attr
		end
		tracks[index] = lang unless tracks.values.include? lang
	end
	tracks['none'] = 'none' if clean
	return tracks
end


def main(file, series, output_main_dir, clean, update)
	file = Pathname.new(file)
	if file.directory?
		files = file.children.select do |cfile| cfile.file? end.sort
		files.each_with_index do |cfile, i|
			print "#{i + 1}/#{files.size} "
			main(cfile, series, output_main_dir, clean, update)
		end
	elsif file.file?
		run(file, series, output_main_dir, clean, update)
	end
end


def get_output_dir(output_main_dir, series, filename)
	return "#{output_main_dir}/#{series}/#{filename}"
end


main(input_folder, series, output_main_dir, clean, update)
