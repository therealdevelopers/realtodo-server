require "webrick"
require Dir.getwd + "/config"
require Dir.getwd + "/json_base"

class Server
	attr_accessor :config
	
	public
	
	def initialize(cfg_path)
		init_config cfg_path
		init_base path: @config.settings.db_path, max_pushes: @config.settings.max_pushes
		init_server @config.settings.port
	end
	
	def start
		puts "[INFO] server\t: start\t: Server start!"
		@http_server.start unless @http_server.nil?		
	end
	
	def shutdown
		@data_base.save
		@http_server.shutdown
	end
	
	private
		def push(passname, tasks)
		options = {:passname => passname}
		@data_base.add_tasks options, tasks
	end
	
	def pull(passname, index)
		@data_base.get_push(passname: passname, index: index)
	end
	
	def init_server(port)
		create_server port
		mount_procs
		mount_index
	end

	def set_config(options = {})
		@config.set(options) unless !@config.nil?
	end
	
	def init_config
		@config = Config.new
	end
	
	def init_config(path)
		@config = Config.new
		@config.load_or_create(path)
	end
	
	def init_config(path, options = {})
		@config = Config.new
		@config.load_or_create(path)
		@config.set(options)
	end
	
	def init_base(options = {})
		@data_base = JsonBase.new(options)
	end
	
	def mount_push
		@http_server.mount_proc("/push") { |req, resp|
			begin
			resp.body = PushResponse.new(status: push(req.query["passname"].delete("\""), req.query["tasks"].delete("\"").to_s), message: "OK").to_json
			rescue Exception => e
				resp.body = PushResponse.new(status: false.to_s, message: e.message + "\n #{e.backtrace.inspect}").to_json
			end
		}
	end
	
	def mount_pull
		begin
		@http_server.mount_proc("/pull") {|req, resp|
			resp.body = PullResponse.new(status: true.to_s, message: "OK", tasks: pull(req.query["passname"].delete("\""), req.query["index"].delete("\"").to_i)).to_json
		}
		rescue Exception => e
				resp.body = PullResponse.new(status: false.to_s, message: e.message + "\n #{e.backtrace.inspect}").to_json
		end
	end
	
	def mount_procs
		mount_push
		mount_pull
	end
	
	def mount_index
		@http_server.mount_proc("/") {|req, resp|
			resp.body = "<h1>It's working, bratok!</h1>"
			resp['Content-Type'] = 'text/html'
		}
	end
	
	def create_server(port)
		@http_server = WEBrick::HTTPServer.new(:Port => port)
	end
	
end
	
	class PushResponse
		attr_reader :meta
		
		def initialize(options = {})
			options.default = ""
			@meta = {}
			if !options.nil? then
				@meta[:status] = options[:status]
				@meta[:message] = options[:message]
			end
		end
		
		def to_json
			return @meta.to_json
		end
	end
	
	class PullResponse
		attr_reader :tasks, :meta
		
		def initialize(options = {})
			options.default = ""
			@meta = {}
			@tasks = options[:tasks]
			@meta[:status] = options[:status]
			@meta[:message] = options[:message]
		end
		
		def to_json
			hash = {}
			hash[:meta] = @meta
			hash[:tasks] = @tasks
			return hash.to_json
		end
	end
