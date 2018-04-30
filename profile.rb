#!/bin/env ruby

############################################################
###                    profile.rb v2                     ###
###                  by Noah Rosenzweig                  ###
############################################################
###  USAGE:                                              ###
###   Profile criteria from command line:                ###
### $ ./profile.rb profile1,~not_profile2,\!not_profile3 ###
###   Files to process from command line:                ###
### $ ./profile.rb profile file1,filealias1,file2        ###
############################################################

require 'yaml'
require 'pathname'

## Get root directory of this script
ROOT = (Pathname.new(File.absolute_path(__FILE__)).realpath).dirname.to_s
HOME = Dir.home
HOSTNAME = `hostname`.strip

## require my ArgumentParser Ruby command-line argument parser gem
#require File.join(ROOT, 'ArgumentParser.rb')

## Monkey patch in to_regexp method to String
class String
	def to_regexp
		slashes = self.count '/'
		return Regexp.new(self)  if     (slashes == 0)
		return nil               unless (slashes == 2)
		split = self.split("/")
		options = (
			(split[2].include?("x") ? Regexp::EXTENDED : 0) |
			(split[2].include?("i") ? Regexp::IGNORECASE : 0) |
			(split[2].include?("m") ? Regexp::MULTILINE : 0)
		)              unless (split[2].nil?)
		options = nil  if (split[2].nil?)
		return Regexp.new(split[1], options)
	end
end

## Default config paths
CONFIG_PATHS = [
	File.join(HOME, '.config/profilerb/config.yml'),
	File.join(HOME, '.profilerb.yml'),
	File.join(ROOT, 'config.yml')
]

## Default Keywords
DEFAULT_KEYWORDS = {
	single:       /^\s*.PROFILE=/,
	block_start:  /^\s*.PROFILE_START=/,
	block_end:    /^\s*.PROFILE_END/,
}
DEFAULT_SEPARATOR = '='

## Default profile(s)
DEFAULT_PROFILES = [
	'default',
	'$HOSTNAME'
]

def get_config_file
	ret = nil
	CONFIG_PATHS.each do |file|
		if (File.file? file)
			ret = YAML.load_file file
			break
		end
	end
	return ret
end

## Get config
CONFIG = get_config_file || {}

## Handle KEYWORDS
SEPARATOR = CONFIG['keywords'] ? (CONFIG['keywords']['separator'] ? Regexp.quote(CONFIG['keywords']['separator']) : DEFAULT_SEPARATOR) : DEFAULT_SEPARATOR
KEYWORDS = CONFIG['keywords'] ? (CONFIG['keywords'].map do |key,val|
	next nil  if (key == 'separator')
	value = val.gsub DEFAULT_SEPARATOR, SEPARATOR
	regexp = value.to_regexp
	abort [
		"Error: '#{value}' doesn't seem to be a valid Regular Expression.",
		"  Make sure that you have either surrounded it with slashes ('/'),",
		"  or didn't use any slashes at all.",
		"  If you want to use slashes, escape them ('\\/')."
	].join("\n")  if (regexp.nil? || !regexp.is_a?(Regexp))
	nex = [
		key.to_sym,
		regexp
	]
	next nex
end .reject { |v| v.nil? } .to_h) : DEFAULT_KEYWORDS

## Handle file_aliases
FILE_ALIASES = CONFIG['file_aliases'].map do |key,val|
	nex = [key.to_sym, val]
	nex[1].gsub! /(\$HOME)|~/, HOME  if (val =~ /\$HOME/)  # Replace '$HOME' or '~' with full home directory path
	nex[1].gsub! /(\$ROOT)/, ROOT    if (val =~ /\$ROOT/)  # Replace '$ROOT' with root directory of this script
	next nex
end .to_h

## Handle files
# Determine which files to use; from command-line or from config
files = ARGV[1] ? ARGV[1].split(',') : (CONFIG['files'] || abort([
	"Error: No files specified in config or from command-line.",
	"  Nothing to do."
].join("\n")))
FILES = files.map do |file|
	nex = FILE_ALIASES[file.to_sym] || file
	## Read all files in directory if file is directory
	if    (File.directory? nex)
		nex = Dir.new(nex).map do |f|
			fpath = File.join(nex, f)
			next fpath  if (File.file? fpath)
		end .reject { |x| !x }
	elsif (!File.file?(nex))
		abort [
			"Error: File #{nex} doesn't exist."
		].join("\n")
	end
	next nex
end .flatten

## Set profiles
profiles = []
profiles_not = []
if (ARGV[0])
	profiles = ARGV[0].split ","
else
	## Default profile(s) to use according to your machine's hostname,
	## unless profiles are given on command line
	if (hostname_profiles = CONFIG['hostname_profiles'])
		profiles = hostname_profiles[HOSTNAME] || hostname_profiles['default'] || DEFAULT_PROFILES
	else
		# No profiles defined anywhere, use hard-coded default
		profiles = DEFAULT_PROFILES
	end
end

## Replace '$HOSTNAME' with actual hostname in profiles
profiles.map! { |p| next p.gsub(/\$HOSTNAME/, HOSTNAME) }

## Filter out negated profiles ('!' || '~')
profiles.each do |profile|
	if (profile[0] =~ /!|~/)
		profiles_not << profile.gsub(/!|~/, "")
		profiles.delete profile
	end
end

PROFILES = profiles
PROFILES_NOT = profiles_not


def main args
	profiles = args[:profiles]
	profiles_not = args[:profiles_not]
	files = args[:files]

	files.each do |file|
		## Loop through files

		blocks = []
		lines = File.read(file).split("\n")
		lines_processed = []
		lines.each do |line|
			## Loop through each line in file

			match = KEYWORDS.map { |k,v| next k  if (line =~ v) } .reject { |k| k.nil? || k == :separator } .first
			if (match)
				## Keyword found, check type
				case match
				when :single
					blocks << {
						type:     :single,
						criteria: line.match(/#{SEPARATOR}.+/).to_s.delete("#{SEPARATOR}").gsub(/([A-z0-9\-_]+)/, 'vars["\1"]'),
						comment:  line.match(/\S/).to_s
					}
				when :block_start
					blocks << {
						type:     :block,
						criteria: line.match(/#{SEPARATOR}.+/).to_s.delete("#{SEPARATOR}").gsub(/([A-z0-9\-_]+)/, 'vars["\1"]'),
						comment:  line.match(/\S/).to_s
					}
				when :block_end
					blocks.delete blocks.last
				end

			else
				## No keyword found, manipulate line if necessary
				if (blocks.last)
					block = blocks.last
					vars = {}

					## Set variables
					block[:criteria].scan(/\["\S+"\]/).uniq.each do |profile|
						profile.gsub!(/\["|"\]/, "")
						if (profiles.include? profile)
							vars[profile] = true
						elsif (profiles_not.any? && !profiles_not.include?(profile))
							vars[profile] = true
						else
							vars[profile] = false
						end
					end

					## Check if profiles match criteria
					if ( eval( block[:criteria] ) )
						# MATCHES - uncomment
						if (line.match(/\S{2}/).to_s == block[:comment] * 2)
							line.sub! block[:comment] * 2, ""
						end
					else
						# DOESN'T MATCH - comment out
						unless (line.match(/\S{2}/).to_s == block[:comment] * 2)
							white = line.match /\A[ \t]*/
							line.sub! /#{white}/, "#{white}#{block[:comment] * 2}"  unless (line.match(/\S/).to_s == block[:comment])
						end
					end

					blocks.delete block  if (block[:type] == :single)
				end

			end

			## Add line to array of lines (which will be written to file)
			lines_processed << line

		end

		# Add new line to end of file
		#lines_processed << "\n"

		## Write to file
		f = File.new file, "w"
		f.write lines_processed.join("\n")
		f.close

	end

end

puts "Profiles:\n\t#{PROFILES.join("\n\t")}"
puts "Files:\n\t#{FILES.join("\n\t")}"

main profiles: PROFILES, profiles_not: PROFILES_NOT, files: FILES

puts "DONE"
