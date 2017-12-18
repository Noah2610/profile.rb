#!/bin/env ruby

require 'byebug'

############################################################
###                    profile.rb v2                     ###
###                  by Noah Rosenzweig                  ###
############################################################

############################################################
###  USAGE:                                              ###
###   Profile criteria from command line:                ###
### $ ./profile.rb profile1,~not_profile2,\!not_profile3 ###
###   Files to process from command line:                ###
### $ ./profile.rb profile file1,filealias1,file2        ###
############################################################

HOME = "/home/noah"
file_aliases = {
	bashrc:        "#{HOME}/.bashrc",
	vimrc:         "#{HOME}/.vimrc",
	xmodmap:       "#{HOME}/.Xmodmap",
	i3config:      "#{HOME}/.config/i3/config",
	i3status:      "#{HOME}/.config/i3/i3status.conf",
	wrapper:       "#{HOME}/.config/i3/wrapper.py",
	togglemouse:   "#{HOME}/.config/i3/scripts/togglemouse.sh",
	termite:       "#{HOME}/.config/termite/config"
}
files = [
	file_aliases[:i3config],
	file_aliases[:i3status],
	file_aliases[:wrapper],
	file_aliases[:togglemouse],
	file_aliases[:termite],
	file_aliases[:bashrc]
]
KEYWORDS = {
	single:       /\s*.PROFILE=/,
	block_start:  /\s*.PROFILE_START=/,
	block_end:    /\s*.PROFILE_END/,
}

profiles = []
profiles_not = []
if (ARGV[0])
	profiles = ARGV[0].split ","
else
	case `hostname`.strip
	when 'desktop-arch'
		profiles = ["h77m-arch"]
	when 'noah-acer'
		profiles = ["acer"]
	when 'aware-desktop'
		profiles = ["aware"]
	end
end
## Filter out negated profiles ('!' || '~')
profiles.each do |profile|
	if (profile[0] == "!" || profile[0] == "~")
		profiles_not << profile
		profiles.delete profile
	end
end

files = ARGV[1].split ","  if ARGV[1]


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

			## Handle blocks
			if (blocks.last)
				block = blocks.last

				vars = {}
				#criteria = block[:criteria].dup
				#criteria.gsub! /([A-z0-9\-_]+)/, 'vars["\1"]'

				## Set variables
				block[:criteria].scan(/[A-z0-9\-_]+/).uniq.each do |profile|
					if (profiles.include? profile)
						eval "vars[\"#{profile}\"] = true"
					elsif (profiles_not.include? profile)
						eval "vars[\"#{profile}\"] = false"
					else
						eval "vars[\"#{profile}\"] = false"
					end
				end

				## Check if profiles match criteria
				if ( eval( block[:criteria] ) )
					# MATCHES - uncomment
					if (line.match(/\S{2}/).to_s == block[:comment] * 2)
						line = line.sub block[:comment] * 2, ""
					end
				else
					# DOESN'T MATCH - comment out
					unless (line.match(/\S{2}/).to_s == block[:comment] * 2)
						line = "#{block[:comment] * 2}#{line}"
					end
				end

				blocks.delete block  if (block[:type] == :single)
			end

			match = KEYWORDS.map { |k,v| k  if (line =~ v) } .reject { |v| v.nil? } .first
			if (match)
				# Keyword found, check type
				case match
				when :single
					blocks << {
						type:     :single,
						criteria: line.match(/=.+/).to_s.delete("=").gsub(/([A-z0-9\-_]+)/, 'vars["\1"]'),
						comment:  line.match(/\S/).to_s
					}
				when :block_start
					blocks << {
						type:     :block,
						criteria: line.match(/=.+/).to_s.delete("=").gsub(/([A-z0-9\-_]+)/, 'vars["\1"]'),
						comment:  line.match(/\S/).to_s
					}
				when :block_end
					blocks.delete blocks.last
				end

			end

			## Add line to array of lines (which will be written to file)
			lines_processed << line

		end

		# Add new line to end of file
		lines_processed << "\n"

		## Write to file
		f = File.new file, "w"
		f.write lines_processed.join("\n")
		f.close

	end

end

puts "Profiles:\t#{profiles.join(", ")}"
puts "Files:\t\t#{files.join(", ")}"

main profiles: profiles, profiles_not: profiles_not, files: files

puts "DONE"

