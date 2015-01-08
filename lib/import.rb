require "net/https"
require "uri"
require 'json'
require 'csv'
require 'fileutils'
require 'pry'

module Import
	SITE = "https://maps.googleapis.com/"
	API_KEY = "AIzaSyCQNeAF-rK3NqPG0gFYQPiZAI50bMl2rLE"
	BACKUP_DIR = "./db/backup/"

	FIELDS = {
		"lp" => {:required => true},
		"country" => {:required => true},
		"city" => {:required => true},
		"district" => {:required => true},
		"area" => {:required => true},
		"title" => {:required => true},
		"description" => {:required => true},
		"local" => {:required => true},
		"total_cost" => {:required => true},
		"upkeep_cost" => {:required => false},
		"is_rejected" => {:required => false},
		"full_description" => {:required => false},
		"justification" => {:required => false},
		"category" => {:required => false},
		"target_group" => {:required => false},
		"status" => {:required => false},
		"budget_id" => {:required => true},
		"votes_count" => {:required => false},
		"project_id" => {:required => false},
	}

	def self.validate_header(file)
		if not valid_header?(@csv)
			missing_fields = get_missing_fields(@csv)
			throw "Brak wymaganych pól: #{missing_fields}"
		end
	end

	def self.valid_header?(rows)
		header = get_header(rows)
		FIELDS.select { |_,v| v[:required] }.all? { |k,_| header.include?(k) }
	end

	def self.map_fields(rows)
		header = get_header(rows)
		Hash[ header.each_with_index.map { |field, index| [field, index] if FIELDS.has_key?(field) } ]
	end

	def self.get_file_data(filename)
		filedata = filename.split("/").last.split(".")[0]
		filedata.split("_")
	end

	def self.get_missing_fields(rows)
		header = get_header(rows)
		FIELDS.select { |_,v| v[:required] }.find_all { |k,_| not header.include?(k) }
	end

	def self.get_header(rows)
		rows[0].map(&:downcase)
	end

	def self.start(filename)
		@filename = "./db/" + filename
		@city, @from, @to = get_file_data(@filename)
		init unless @is_inited
		@csv = CSV.read @filename

		validate_header(@csv)
		@fields = map_fields(@csv)

		@size = @csv.size - 3
		# @csv[3..-1].each_with_index {|row, i| update_row(row, i)}
		@csv[6..-1].each_with_index {|row, i| create_from_row(row, i)}
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

	def self.get_row(row, name)
		row[@fields[name]]
	end

	def self.create_from_row row, i=0
		#return unless row[9] || row[11]
		@district, @title, @local = get_row(row,'district'), get_row(row,'title'), get_row(row,'local')
		if not @local.nil? and @local.include?(',')
			@local = @local.split(',')[0]
		end

		if @district.nil?
			@district = ''
		end

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
			:abstract => get_row(row,'description'),
			:total_cost => get_row(row,'total_cost'),
			:upkeep_cost => "0 zł", 
			:is_rejected => false,
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