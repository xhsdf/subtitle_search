#!/usr/bin/ruby

require 'pathname'
require 'fileutils'
require 'rexml/document'
require 'shellwords'
include REXML

input_folder = ARGV[0]
output_main_dir = ARGV[1]
series = ARGV[2]
clean = ARGV.include? '--clean'


def run(file, series, output_main_dir, clean)
	filename = file.basename
	puts filename
	output_dir = "#{output_main_dir}/#{series}/#{filename}"
	FileUtils.mkdir_p output_dir
	
	get_subtitle_tracks(file, clean).each do |index, lang|
		puts "  extracting subtitle track: #{lang}..."
		subtitle_dir = "#{output_dir}/#{lang}"
		FileUtils.mkdir_p subtitle_dir
		sub_param = ""
		if lang != 'none'
			system("ffmpeg -i \"#{file}\" -loglevel error -y -map 0:#{index} \"#{subtitle_dir}.ass\"")
			sub_param = ", ass=#{Shellwords.escape(subtitle_dir.gsub("'", "\\\\\\\\'"))}.ass"
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
		tracks[index] = lang unless tracks.values.include? lang
	end
	tracks['none'] = 'none' if clean
	return tracks
end


def main(file, series, output_main_dir, clean)
	file = Pathname.new(file)
	if file.directory?
		files = file.children.select do |cfile| cfile.file? end.sort
		files.each_with_index do |cfile, i|
			print "#{i + 1}/#{files.size} "
			main(cfile, series, output_main_dir, clean)
		end
	elsif file.file?
		run(file, series, output_main_dir, clean)
	end
end


main(input_folder, series, output_main_dir, clean)
