require "webrick"
require Dir.getwd + "/config"
require Dir.getwd + "/json_base"

class Server
	attr_accessor :config
	
	public
	
	def initialize(cfg_path)
		@cfg_path = cfg_path
		init_config @cfg_path
		init_base path: @config.settings.db_path, max_pushes: @config.settings.max_pushes
		init_server @config.settings.port
	end
	
	def start
		puts "[INFO] server\t: start\t: Server start!"
		@http_server.start unless @http_server.nil?		
	end
	
	private
	
	def shutdown
		@data_base.save
		@http_server.shutdown
	end
	
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
		mount_config_info
		mount_config
		mount_restart
		mount_stop
		mount_chpass
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
	
	def mount_config_info
		@http_server.mount_proc("/config/settings") {|req, resp|
			resp.body = "<h1>Config info</h1>"
			resp.body += get_config_info.to_json
		}
	end
	
	def mount_config
		@http_server.mount_proc("/config") {|req, resp|
			result_set = Hash.new
			@config.config_list.each {|option| 
				new_value = req.query option
				unless (new_value.nil?)
				{
					result_set[option.to_sym] = new_value
				}
			}
			return @config.set result_set
		}
	end
	
	def mount_restart
		@http_server.mount_proc("/server/restart") {|req, resp|
			_pass = query["pass"]
			resp.body = restart(pass).to_json
		}
	end
	
	def mount_stop
		@http_server.mount_proc("/server/stop") {|req, resp|
			_pass = req.query["pass"]
			stop pass
		}
	end
	
	def mount_chpass
		@http_server.mount_proc("/server/chpass") {|req, resp|
			begin
				_newpass = req.query["newpass"]
				_oldpass = req.query["oldpass"]
				resp.body = change_pass(newpass: _newpass, oldpass: _oldpass).to_json
			rescue Exception => e
				resp.body = {:status => "Error", :message => e.message}
			end
		}
	end
	
	def get_config_info
		return @config.info
	end
	
	def change_pass(options)
		if(check_pass options[:oldpass]) then
			@config.rootpass = options[:newpass]
			return {:status => "OK"}
		else
			return {:status "Fail", :message => "Incorrect password"}
		end
	end
	
	def check_pass password
		return @config.rootpass == password
	end
	
	def restart pass
		begin
			if(check_pass pass) then
				shutdown
				initialize @cfg_path
				start
				return {:status => "OK", :message => "Server is working now!"}
			else
				return {:status "Fail", :message => "Incorrect password"}
			end
		rescue Exception => e
			return {:status => "Error", :message => e.message}
	end
	
	def stop pass
		begin
			if(check_pass pass) then
				shutdown
			else
				return {:status "Fail", :message => "Incorrect password"}
			end
		rescue Exception => e
			return {:status => "Error", :message => e.message}
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
