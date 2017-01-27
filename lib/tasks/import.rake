namespace :import do

  class String
    def trimzero
      self.sub(/^[0:]*/, "")
    end
  end

  desc "Import routes from LAD"
  task routes: :environment do
    routes = []

    iterate_over_url "http://82.207.107.126:13541/SimpleRide/LAD/SM.WebApi/api/CompositeRoute/" do |item|
      route = Route.find_or_initialize_by(external_id: item[:Id])
      route.code = item[:Code]
      route.name = item[:Name]
      route.save

      routes << route
    end

    routes.each do |route|
      route.stops = []
      iterate_over_url "http://82.207.107.126:13541/SimpleRide/LAD/SM.WebApi/api/CompositeRoute/?code=#{route.code}" do |stop|
        stop = Stop.where(code: stop[:Code].trimzero).first
        route.stops << stop if stop
      end

      route.save

      p "Imported #{route.name}"
    end

  end

  desc "Import stops from LAD"
  task stops: :environment do
    stops = []

    iterate_over_url "http://82.207.107.126:13541/SimpleRIDE/LAD/SM.WebApi/api/stops" do |item|
      stops << item
    end

    stops.each do |item|
      item[:Code] = item[:Code].trimzero

      begin
        Integer(item[:Code])
      rescue
        p "Code #{item[:Code]} for #{item[:Name]} is bad value"
        next
      end

      stop = Stop.find_or_initialize_by(external_id: item[:Id])

      stop.code = item[:Code]
      stop.name = item[:Name]
      stop.longitude = item[:X]
      stop.latitude = item[:Y]

      # Skip ugly stop on edge of the city
      next if stop.external_id == 45592;

      # If this stop is not in Lviv - skip it
      if stop.code.to_i > 803
        next
      end

      stop.save
    end
  end

  def iterate_over_url(url)
    raw_data = %x(curl --silent "#{url}" -H "Accept: application/xml")

    n = Nokogiri::XML(raw_data)
    JSON.parse(n.remove_namespaces!.xpath('//string').text).each do |item|
      item = item.with_indifferent_access
      yield item
    end
  end

end
