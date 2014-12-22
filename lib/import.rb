require "net/https"
require "uri"
require 'json'
require 'csv'

module Import
	SITE = "https://maps.googleapis.com/"
	API_KEY = "AIzaSyCQNeAF-rK3NqPG0gFYQPiZAI50bMl2rLE"

	def self.start
		init unless @is_inited
		@filename = "./db/Warszawa - Sheet2.csv"
		@csv = CSV.read @filename
	end



	def self.create_from_row row
		if row[5]=="1"
			budget_hash = {
				:name => row[2] + " - " + row[3],
				:type => row[10],
				:value => 0
			}
			@budget = Budget.create budget_hash
		end
		@budget ||= Budget.last
		geo_result = get_location(row[2]+", "+row[11])
		lat = geo_result["location"]["lat"]
		lng = geo_result["location"]["lat"]
		protocol = (geo_result["location_type"] == "ROOFTOP") ? "1" : "2"

		cause_hash = {
			:city => row[2], 
			:district => row[3], 
			:title => row[8], 
			:abstract => row[9] + ", koszt: " + row[12] + ", koszt_utrzymania: " + row[13], 
			:is_rejected => row[18]=="Accepted",
			:budget_id => @budget.id,
			:latitude => lat,
			:longitude => lng,
			:protocol => protocol
		}
		cause = Cause.create cause_hash
		@budget.value += row[12].to_i
		@budget.save
	end


	def self.init
		uri = URI.parse(SITE)
		@http = Net::HTTP.new(uri.host, uri.port)
		@http.use_ssl = true
		@http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		@is_inited = true
	end

	def self.get_location location
		request = Net::HTTP::Get.new("/maps/api/geocode/json?address="+URI.encode(location)+"&key="+API_KEY)
		require 'pry'
		# binding.pry
		response = @http.request(request)
		result = JSON.parse response.body
		
		return result["results"][0]["geometry"]
	end
end