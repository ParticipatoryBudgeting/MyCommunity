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
		@filename = "./db/Warszawa_2014-01-01_2014-12-31.csv"
		filedata = @filename.split("/").last.split(".")[0]
		@city, @from, @to = filedata.split("_") 
		init unless @is_inited
		@csv = CSV.read @filename
		@size = @csv.size - 3
		# update_row(@csv[3], 0)
		# @csv[765..-1].each_with_index {|row, i| create_from_row(row, i)}
		# @csv[3..-1].each_with_index {|row, i| update_row(row, i)}
		@csv[3..-1].each_with_index {|row, i| create_from_row(row, i)}
	end

	def self.save_to_file body, filename
		timestamp = Time.now.strftime("%Y%m%d%H%M%S")
		aggregate_path = [@city, @district, @area].join("/")
		path = BACKUP_DIR + aggregate_path + "/" + filename + timestamp + ".json"
		dirname = File.dirname(path)
		unless File.directory?(dirname)
		  FileUtils.mkdir_p(dirname)
		end
		output_file = File.open path, "w"
		output_file.puts(Time.now.to_s+"\n"+body)
		output_file.close
	end

	def self.check_cache filename
		aggregate_path = [@city, @district, @area].join("/")
		path = BACKUP_DIR + aggregate_path + "/" + filename
		file_path = Dir[path+"*"].last
		return {} unless file_path.present?
		input_file = File.open file_path, "r"
		result = JSON.parse input_file.read[31..-1]
		result["status"] == "OK" ? result["results"][0]["geometry"] : {}
	end

	def self.update_row row, i=0
		return unless row[9] || row[11]
		@district, @id, @title, @area, @local = row[3], row[7], row[8], row[10], row[11].to_s
		p [i, @size].join("/") +  " - #{@title}"
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
		return unless row[9] || row[11]
		@district, @title, @local = row[3], row[5], row[7]
		@id = 0
		@are = ''
		p [i, @size].join("/") +  " - #{@title}"

		# defaults
		lat = 52.13
		lng = 21.00
		location_precission = "3"

		return if @local.nil?

		geo_result = get_location(@city + ", " + @local)
		if geo_result.present? && @local.present?
			location_precission = (geo_result["location_type"] == "ROOFTOP") ? "1" : "2"
		else
			location_precission = "3"
			geo_result = get_location(@city)
		end
		lat = geo_result["location"]["lat"]
		lng = geo_result["location"]["lng"]

		# TODO: create
		category = Category.first

		cause_hash = {
			:city => @city, 
			:district => @district, 
			:title => @title,
			:local => @local, 
			:abstract => row[6],
			:total_cost => row[8],
			:upkeep_cost => "0 zł", 
			:is_rejected => row[18]=="Accepted",
			:budget_id => @budget.id,
			:latitude => lat,
			:longitude => lng,
			:location_precission => location_precission,
			:area => @area,
			:author => @user.name,
			:submited => true,
			:category => category,
			:user => @user
		}
		cause = Cause.create cause_hash
		if not cause.valid?
			p cause.errors.full_messages
		end

		cause
	end

	def self.init
		init_api_client
		init_user
		init_category
		init_budget
		@is_inited = true
	end

	def self.init_user
		user = User.find_by_name "Stefan Batory"
		user = User.create(:name => "Stefan Batory", :username => "Stefan Batory", :facebook_id => 1) if user.nil?
		@user = user
	end

	def self.get_location location
		request = Net::HTTP::Get.new("/maps/api/geocode/json?address="+URI.encode(location)+"&key="+API_KEY)

		response = @http.request(request)
		save_to_file response.body, "project#{@id}_"
		result = JSON.parse response.body
		
		result["status"] == "OK" ? result["results"][0]["geometry"] : {}
	end

	def self.init_api_client
		uri = URI.parse(SITE)
		@http = Net::HTTP.new(uri.host, uri.port)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	end

	def self.init_budget
		budget_hash = {
			:name => @filename.split("/").last,
			:type => "Budżet Partycypacyjny",
			:value => 0
		}
		@budget = Budget.create(budget_hash) { |b| b.user = @user }
	end

	def self.init_category
		category = Category.first
		category = unless category
			Category.create(:name => "Zwykła")
		end
		@category = category
	end
end