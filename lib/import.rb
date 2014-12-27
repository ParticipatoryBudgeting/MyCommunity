require "net/https"
require "uri"
require 'json'
require 'csv'
require 'fileutils'

module Import
	SITE = "https://maps.googleapis.com/"
	API_KEY = "AIzaSyCQNeAF-rK3NqPG0gFYQPiZAI50bMl2rLE"
	BACKUP_DIR = "./db/backup/"

	def self.start filename=nil
		@filename = "./db/Warszawa_2013-01-01_2013-12-31.csv"
		filedata = @filename.split("/").last.split(".")[0]
		@city, @from, @to = filedata.split("_") 
		init unless @is_inited
		@csv = CSV.read @filename
		@size = @csv.size - 3
		require 'pry'
		# binding.pry
		# update_row(@csv[3], 0)
		# @csv[765..-1].each_with_index {|row, i| create_from_row(row, i)}
		@csv[3..-1].each_with_index {|row, i| update_row(row, i)}

	end

	def self.save_to_file body, filename
		timestamp = Time.now.strftime("%Y%m%d%H%M%S")
		aggregate_path = [@city, @district, @area].join("/")
		path = BACKUP_DIR + aggregate_path + "/" + filename + timestamp + ".json"
		dirname = File.dirname(path)
		unless File.directory?(dirname)
		  FileUtils.mkdir_p(dirname)
		end
		require 'pry'
		# binding.pry		
		output_file = File.open path, "w"
		output_file.puts(Time.now.to_s+"\n"+body)
		output_file.close
	end

	def self.check_cache filename
		aggregate_path = [@city, @district, @area].join("/")
		path = BACKUP_DIR + aggregate_path + "/" + filename
		require 'pry'
		# binding.pry
		file_path = Dir[path+"*"].last
		return {} unless file_path.present?
		input_file = File.open file_path, "r"
		result = JSON.parse input_file.read[31..-1]
		result["status"] == "OK" ? result["results"][0]["geometry"] : {}
	end

	def self.update_row row, i=0
		return unless row[9] || row[11]
		@district, @id, @title, @area, @local = row[3], row[7], row[8], row[10], row[11].to_s
		p [i, @size].join("/") + " - " + @title
		geo_result = check_cache "project#{@id}_"
		if geo_result.present?
			lat = geo_result["location"]["lat"]
			lng = geo_result["location"]["lng"]
			cause_hash = {
				:latitude => lat,
				:longitude => lng,
			}
			c = Cause.find_by_title(@title).update_attributes cause_hash
			p "Updated"
		end
	end

	def self.create_from_row row, i=0
		require 'pry'
		# binding.pry
		return unless row[9] || row[11]
		@district, @id, @title, @area, @local = row[3], row[7], row[8], row[10], row[11].to_s
		p [i, @size].join("/") + " - " + @title
		geo_result = get_location(@city + ", " + @local)
		if geo_result.present? && @local.present?
			location_precission = (geo_result["location_type"] == "ROOFTOP") ? "1" : "2"
		else
			location_precission = "3"
			geo_result = get_location(@city)
		end
		lat = geo_result["location"]["lat"]
		lng = geo_result["location"]["lng"]

		cause_hash = {
			:city => @city, 
			:district => @district, 
			:title => @title,
			:local => @local, 
			:abstract => row[9],		#sometimes it's longer
			:total_cost => row[12],
			:upkeep_cost => row[13], 
			:is_rejected => row[18]=="Accepted",
			:budget_id => @budget.id,
			:latitude => lat,
			:longitude => lng,
			:location_precission => location_precission,
			:area => @area,
			:author => @user.name 
		}
		c = Cause.create cause_hash
		require 'pry'
		# binding.pry
		c
	end

	def self.init
		uri = URI.parse(SITE)
		@http = Net::HTTP.new(uri.host, uri.port)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		@user = get_user
		require 'pry'
		# binding.pry
		budget_hash = {
			:name => @filename.split("/").last,
			:type => "Budżet Partycypacyjny",
			:value => 0,
			:user_id => @user.id
		}
		@budget = Budget.create budget_hash
		@is_inited = true
	end

	def self.get_user
		user = User.find_by_name "Stefan Batory"
		user = User.create(:name => "Stefan Batory", :username => "Stefan Batory", :facebook_id => 1) if user.nil?
		user
	end

	def self.get_location location
		request = Net::HTTP::Get.new("/maps/api/geocode/json?address="+URI.encode(location)+"&key="+API_KEY)
		require 'pry'
		# binding.pry
		response = @http.request(request)
		save_to_file response.body, "project#{@id}_"
		result = JSON.parse response.body
		
		result["status"] == "OK" ? result["results"][0]["geometry"] : {}
	end
end