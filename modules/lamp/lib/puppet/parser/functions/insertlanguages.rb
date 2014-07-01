module Puppet::Parser::Functions
	require 'yaml'
	newfunction(:insertlanguages, :type => :rvalue) do |args|
		languages = lookupvar('languages')
		if languages != nil
			dbname = lookupvar('dbname')
			languages = YAML.load(languages)
			resultado = ''
			languages.each do |lang|
				lang.each do |item|
					resultado = "#{resultado} UPDATE languages set domain = '#{item[1]}' WHERE language = '#{item[0]}';\n"
				end
			end
			"echo \"#{resultado}\" | mysql #{dbname}"
		end
	end
end