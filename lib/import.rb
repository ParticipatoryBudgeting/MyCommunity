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

	# nazwy pól wraz z informacją czy dane pole jest wymagane
	FIELDS = {
		"lp" => true,
		"country" => true,
		"city" => true,
		"district" => true,
		"area" => true,
		"title" => true,
		"description" => true,
		"local" => true,
		"total_cost" => true,
		"upkeep_cost" => false,
		"is_rejected" => false,
		"full_description" => false,
		"justification" => false,
		"category" => false,
		"target_group" => false,
		"status" => false,
		"budget_id" => true,
		"votes_count" => false,
		"project_id" => false,
		"target_group" => false,
		"status" => false
	}

	def self.start(filename, start=1, stop=-1)
		# pre parse actions
		init

		@filename = filename
		@csv = CSV.read @filename

		validate_file(@csv)
		@fields = map_fields(@csv)

		# parse budgets
		budgets = []
		each_row(@csv, start, stop) do |row, i|
			budgets << get_field(row, 'budget_id') if field_set?(row, 'budget_id')
		end
		@budgets = budgets.uniq.reduce({}) do |mem, name|
			puts "budżet: #{name}"
			if budget = Budget.find_by_name(name)
				puts 'budżet found'
				mem.merge({name => budget})
			else
				if budget = Budget.create(:name => name)
					puts 'budżet created'
					mem.merge({name => budget})
				else
					puts 'budżet nil'
					mem.merge({name => nil})
				end
			end
		end

		# parse categories
		categories = []
		each_row(@csv, start, stop) do |row, i|
			categories << get_field(row, 'category') if field_set?(row, 'category')
		end

		@categories = categories.uniq.reduce({}) do |mem, name|
			puts "kategoria: #{name}"
			if category = Category.find_by_name(name)
				puts 'category found'
				mem.merge({name => category})
			else
				if category = Category.create(:name => name)
					puts 'category created'
					mem.merge({name => category})
				else
					puts 'category nil'
					mem.merge({name => nil})
				end
			end
		end

		# parse projects
		results = {:invalid_rows => []}
		each_row(@csv, start, stop) do |row, i| 
			row_result = create_from_row(row, i)
			unless row_result
				results[:invalid_rows] << i
			end
		end

		# summary
		puts "błędnych wierszy: #{results[:invalid_rows].size}"
		puts "błędne wiersze: #{results[:invalid_rows].join(", ")}" if results[:invalid_rows].size > 0
	end

	def self.each_row(file, start, stop)
		file[start..stop].each_with_index do |row, i|
			yield row, i
		end
	end

	def self.rows_num
		@csv.size - 1
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

	def self.get_field(row, name, default=nil)
		if field_exist? name
			field_empty?(row, name) ? '' : row[@fields[name]]
		else
			default
		end
	end

  def self.field_set?(row, field)
  	field = get_field(row, field)
  	not field.nil? and not field.empty?
  end

	def self.field_exist?(name)
		@fields.has_key?(name)
	end

	def self.field_empty?(row, name)
		row[@fields[name]].nil?
	end

	def self.valid_row?(row)
		return false unless field_set?(row, 'city')
		return false unless field_set?(row, 'title')
		return false unless field_set?(row, 'budget_id')

		return true
	end

	def self.create_from_row(row, i=0)
		# some fields are just needed
		return false if not valid_row?(row)

		# set default values for 'semi-required' fields ...
		category = field_set?(row, 'category') ? get_category(get_field(row, 'category')) : nil
		budget = field_set?(row, 'budget_id') ? get_budget(get_field(row, 'budget_id')) : nil
		cuntry = field_set?(row, 'country') ? get_field(row, 'country') : default_country
		is_rejected = if field_set?(row, 'is_rejected')
			!!get_field(row, 'is_rejected')
		elsif field_set?(row, 'status')
			not get_field(row, 'status').downcase == 'accepted'
		else
			false
		end

		# set fields using external services
		city = get_field(row, 'city')
		local = get_field(row, 'local')
		lat, lng, location_precission = get_geo_data(city, local)

		@country = get_field(row, 'country')
		@city = get_field(row, 'city')
		@district = get_field(row, 'district')
		@area = get_field(row, 'area')
		@title = get_field(row, 'title')
		@description = get_field(row, 'description')
		@local = get_field(row, 'local')
		@total_cost = get_field(row, 'total_cost')	

		cause_hash = {
			:city => city, 
			:district => get_field(row, 'district'), 
			:title => get_field(row, 'title'),
			:local => local, 
			:abstract => get_field(row, 'description'),
			:total_cost => get_field(row, 'total_cost'),
			:upkeep_cost => get_field(row, 'upkeep_cost'), 
			:is_rejected => is_rejected,
			:budget_id => budget[:id],
			:latitude => lat,
			:longitude => lng,
			:location_precission => location_precission,
			:area => get_field(row, 'area'),
			:author => @user.name,
			:submited => true,
			:category => category,
			:user => @user,
			:target_group => get_field(row, 'target_group'),
			:status => get_field(row, 'status')
			#:project_id => get_field(row, 'project_id'),
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
		@is_inited = true
	end

	def self.init_user
		user = User.first
		unless user
			user = User.create(:name => "admin", :username => "Administrator", :facebook_id => 1)
		end
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

	def self.validate_file(file)
		if not valid_header?(@csv)
			missing_fields = get_missing_fields(@csv)
			throw "Brak wymaganych pól: #{missing_fields}"
		end
	end

	def self.valid_header?(rows)
		header = get_header(rows)
		FIELDS.select { |_,v| v }.all? { |k,_| header.include?(k) }
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
		FIELDS.reduce([]) { |m, (k,v)| v ? m.push(k) : m }.find_all { |k,_| not header.include?(k) }
	end

	def self.get_header(rows)
		rows[0].map(&:downcase)
	end

	def self.get_geo_data(city, local)
		lat = 52.13
		lng = 21.00
		location_precission = "3"
		return [lat, lng, location_precission]

		geo_result = get_location(city + ", " + local)
		if geo_result.present? && @local.present?
			location_precission = (geo_result["location_type"] == "ROOFTOP") ? "1" : "2"
		else
			location_precission = "3"
			geo_result = get_location(city)
		end
		lat = geo_result["location"]["lat"]
		lng = geo_result["location"]["lng"]
		[lat, lng, location_precission]
	end

	def self.default_category
		@category
	end

	def self.default_country
		'Polska'
	end

	def self.get_category(name)
		if @categories.has_key? name and not @categories[name].nil?
			@categories[name]
		else
			default_category
		end
	end

	def self.get_budget(name)
		if @budgets.has_key? name and not @budgets[name].nil?
			@budgets[name]
		else
			nil
		end
	end

end