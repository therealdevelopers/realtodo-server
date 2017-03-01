require "oj"

class JsonBase
	attr_reader :path, :max_pushes
	
	def db_meta
		return @hash[:meta]
	end
	
	def db_meta=(value)
		@hash[:meta] = value
	end
	
	def initialize(options = {})
		init_vars(options)
		init_hash(@path) unless @path.nil?
	end
	
	def init_vars(options = {})
		@path = options[:path]
		@max_pushes = options[:max_pushes]
	end
	
	def init_hash(path)
		if !File.exists?(@path) then 
			File.open(@path, "w") {|file| file.write Oj.dump default_base_scheme_hash}
			puts "json_base\t: init_hash\t: Creating new db file" 
		end
		puts "[INFO] json_base\t: init_hash\t: Start"
		puts "[INFO] json_base\t: init_hash\t: Reading data in #{@path}"
		data = IO.read(@path)
		puts "[INFO] json_base\t: init_hash\t: Data read: #{data}"
		@hash = Oj.load(data)
		@hash.default = ""
		puts "[INFO] json_base\t: init_hash\t: Data parsed : #{@hash.to_s}"
	end
	
	def get_push(options = {})
		passname = options[:passname]
		index = get_index_by_alias options[:index]
		#puts "json_base : get_push : Trying to pull #{index} push of #{passname}."
		#puts "json_base : get_push : Press return to start!"
		#gets
		#puts "@hash[:user_data] : " + @hash[:user_data].inspect
		#gets
		#puts "@hash[:user_data][passname.to_sym] : " + @hash[:user_data][passname.to_sym].inspect
		#gets
		#puts "@hash[:user_data][passname.to_sym][:pushes] : " + @hash[:user_data][passname.to_sym][:pushes].inspect
		#gets
		#puts "@hash[:user_data][passname.to_sym][:pushes][index] : " + @hash[:user_data][passname.to_sym][:pushes][index].inspect
		#gets
		#puts @hash[:user_data][passname.to_sym][:pushes][index][:tasks]
		return @hash[:user_data][passname.to_sym][:pushes][index][:tasks]
	end
	
	def find_user(user)
		@hash[:users].any? { |u| u == user}
	end
	
	def create_user(passname)
		puts "Creating new user #{passname}"
		@hash[:users] += passname
		@hash[:user_data][passname.to_sym] = { :meta => "", :pushes => Array.new }
	end
	
	def add_tasks(options = {}, tasks)
		passname = options[:passname]
		push = {:meta => "", :tasks => tasks}
		if(find_user passname)
			puts "[INFO] json_base\t: add_tasks\t: Before push\t: " + @hash[:user_data][passname.to_sym][:pushes].inspect
			@hash[:user_data][passname.to_sym][:pushes] += [push]
			puts "[INFO] json_base\t: add_tasks\t: After push\t: " + @hash[:user_data][passname.to_sym][:pushes].inspect
			puts "[INFO] json_base\t: add_tasks\t: Push count\t: " + @hash[:user_data][passname.to_sym][:pushes].size.to_s
			puts @max_pushes.to_s
			@hash[:user_data][passname.to_sym][:pushes].shift if @hash[:user_data][passname.to_sym][:pushes].size > @max_pushes
			puts "[INFO] json_base\t: add_tasks\t: after shifting\t: " + @hash[:user_data][passname.to_sym][:pushes].inspect
		else
			create_user(passname)
			@hash[:user_data][passname.to_sym][:pushes] += [push]
		end
		save
		return true
	end
	
	def save
		puts
		puts "[INFO] json_base\t: save\t: DB saving..."
		File.open(@path, "w") {|file| file.write Oj.dump @hash}
	end

	private
	
	def default_base_scheme_hash
		{
			:meta => "",
			:users => Array.new,
			:user_data => Hash.new
		}
	end
	
	def get_index_by_alias index
		return index if index.is_a? Numeric && index
	end
end
