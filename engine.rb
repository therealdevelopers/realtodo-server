require Dir.getwd + "/server"
class Engine
	def startuem!(cfg_path)
		["Старутем!", "Нам пора, дружок!", "Стартуем!", "Выдох - выдох...вдох!", "Стартуем!", "В дорогу...", "Нам..", "Пора!"].each_with_index {|phrase, i| if i < 5 then puts phrase else print phrase end}
		puts
		go cfg_path
	end
	
	def go(cfg_path)
		server = Server.new(cfg_path)
		trap 'INT' do server.shutdown end
		server.start
	end
end
