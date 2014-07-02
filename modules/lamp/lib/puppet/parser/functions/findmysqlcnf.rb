module Puppet::Parser::Functions
	require 'find'
	newfunction(:findmysqlcnf, :type => :rvalue) do |args|
		Find.find('/etc/init.d/') do |path|
			if path =~ /.*mysql.*/
				File.open(path,'r').each_line do |line|
					if line =~ /.*cnf.*/
						$line = line
						break
					end
				end
				break
			end
		end
		$line.split(' ')[2]
	end
end 