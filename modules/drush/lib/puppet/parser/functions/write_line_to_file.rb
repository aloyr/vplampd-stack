module Puppet::Parser::Functions
	require 'yaml'
	newfunction(:write_line_to_file) do |args|
		filename = args[0]
		str = args[1]
		File.open(filename, 'a') {|fd| fd.puts str}
		aliases = lookupvar('languages')
		if aliases != nil
			aliases = YAML.load(aliases.to_yaml)
		end
	end
end