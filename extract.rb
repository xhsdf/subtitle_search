#!/usr/bin/ruby

require 'pathname'
require 'fileutils'
require 'rexml/document'
include REXML

input_folder = ARGV[0]
output_main_dir = ARGV[1]
series = ARGV[2]
clean = ARGV.include? '--clean'


def run(file, series, output_main_dir, clean)
	filename = file.basename
	puts filename
	FileUtils.mkdir_p "#{output_main_dir}/#{series}/#{filename}"
	
	get_subtitle_tracks(file, clean).each do |index, lang|
		puts "  extracting subtitle track: #{lang}..."
		subtitle_dir = "#{output_main_dir}/#{series}/#{filename}/#{lang}"
		FileUtils.mkdir_p subtitle_dir
		sub_param = ""
		if lang != 'none'
			system("ffmpeg -i \"#{file}\" -loglevel error -y -map 0:#{index} \"#{subtitle_dir}.ass\"")
			sub_param = ", ass='#{subtitle_dir}.ass'"
		end
		puts "  extracting screencaps with subtitle track: #{lang}..."
		system("ffmpeg -i \"#{file}\" -loglevel error -start_number 0 -stats -vf \"scale=-1:480, fps=1#{sub_param}\" -q:v 1 \"#{subtitle_dir}\"/%d.jpg")
	end
end


def get_subtitle_tracks(file, clean = true)
	tracks = {}
	ffprobe = `ffprobe -v error -of xml -show_streams -select_streams s "#{file}"`
	xmldoc = Document.new(ffprobe)
	XPath.each(xmldoc, "/ffprobe/streams/stream") do |stream|
		index = stream.attribute('index')
		lang = 'unknown'
		XPath.each(stream, "tag[@key = 'language']/@value") do |lang_attr|
			lang = lang_attr
		end
		tracks[index] = lang
	end
	tracks['none'] = 'none' if clean
	return tracks
end


def main(file, series, output_main_dir, clean)
	file = Pathname.new(file)
	if file.directory?
		file.children.select do |cfile| cfile.file? end.each do |cfile|
			main(cfile, series, output_main_dir, clean)
		end
	elsif file.file?
		run(file, series, output_main_dir, clean)
	end
end


main(input_folder, series, output_main_dir, clean)
