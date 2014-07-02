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
			# File.open('/vagrant/data/insertlanguages.sql','w') {|f| f.write(resultado)}
			"echo \"#{resultado}\" | mysql #{dbname}"
		end
	end
end