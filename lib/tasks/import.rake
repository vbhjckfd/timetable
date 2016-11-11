namespace :import do
  desc "Import stops from LAD and LET"
  task stops: :environment do
    stops = {}

    url = "http://82.207.107.126:13541/SimpleRIDE/LAD/SM.WebApi/api/stops"
    raw_data = %x(curl --silent "#{url}" -H "Accept: application/xml")

    n = Nokogiri::XML(raw_data)
    JSON.parse(n.remove_namespaces!.xpath('//string').text).each do |item|
      item = item.with_indifferent_access

      stops[item[:Code]] = item
    end

    mapping = {code: :Code, name: :Name, longitude: :X, latitude: :Y}

    stops.values.each do |item|
      stop = Stop.find_or_initialize_by(external_id: item[:Id])

      stop.code = item[:Code].sub(/^[0:]*/, "")
      stop.name = item[:Name]
      stop.longitude = item[:X]
      stop.latitude = item[:Y]

      begin
        Integer(stop.code)
      rescue
        p "Code #{stop.code} for #{stop.name} is bad value"
        next
      end

      # Skip ugly stop on edge of the city
      next if stop.external_id == 45592;

      # If this stop is not in Lviv - skip it
      if stop.code.to_i > 741
        next
      end

      stop.save
    end
  end

end
