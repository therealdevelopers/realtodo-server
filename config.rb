require "json"

class Config

	attr_accessor :settings, :meta

	def initialize()
	
	end

	def load_or_create(path, options = {})
		if(File.exists?(path))
			load(path)
		else
			if(!options.empty?)
				@settings = Settings.new(options[:settings])
				@meta = options[:meta]
				save(path)
			end
		end
	end
	
	def set(options = {})
		@meta = options[:meta]
		settings.set(options[:settings])
	end
	def load(path)
			return false unless File.exist?(path) && File.readable?(path)
			
			loaded_hash = JSON.parse(IO.read(path), {:symbolize_names => true})
			puts "[INFO] config\t: load\t: Loaded config : " + loaded_hash.inspect
			@meta = loaded_hash[:meta]
			@settings = Settings.new(options = loaded_hash[:settings])							
		rescue
			File.append("log", "a") {|file| file.write "Exception in Config.load"}
			return false
	end
	
	def save(path)
			return false if path.empty?
			File.open(path, "w+"){|file| file.write(self.to_json)}
		rescue
			return false
		
	end
	
	def to_hash
        hash = {}
        hash[:meta] = @meta
        hash[:settings] = @settings.to_hash
        return hash
    end
    
    def to_json
		return to_hash.to_json
	end
end

class Settings
	attr_accessor :port, :db_path, :client_max_speed, :max_pushes, :encoding
	
	def initialize(options = {})
		@port = options[:port]
		@db_path = options[:db_path]
		@client_max_speed = options[:client_max_speed]
		@max_pushes = options[:max_pushes]
		@encoding = options[:encoding]
	end
	
	def set(options = {})
		unless options.nil?
			@port = options[:port]
			@db_path = options[:db_path]
			@client_max_speed = options[:client_max_speed]
			@max_pushes = options[:max_pushes]
			@encoding = options[:encoding]
		end
	end
	def to_hash
        hash = {}
        hash[:port] 			= @port
        hash[:db_path] 			= @db_path
        hash[:client_max_speed] = @client_max_speed
        hash[:max_pushes] 		= @max_pushes
        hash[:encoding] 		= @encoding
        return hash
    end
end

def config_test
	options = {
			:meta => "Участок мета-информации",
			:settings => {
							:port => 8080,
							:db_path => "test_base.json",
							:client_max_speed => 1
						 }
			  }	  
	c = Config.new(options)
	puts c.meta
	puts c.settings.port
	puts c.settings.db_path
	puts c.settings.client_max_speed
	c.save("test_config.json")
end
