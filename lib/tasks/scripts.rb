stops = Stop.all.map{|s| s.code }
stops.each do |stop|
  url = "http://localhost:9999/stops/#{stop}/pdf/sign"
  file_path = "/Users/mholyak/Downloads/stickers/#{stop}.pdf"
  #tiff_file_path = "/Users/mholyak/Downloads/stickers/#{stop}.tiff"
  #p url
  #p file_path
  %x(curl -o "#{file_path}" --silent "#{url}")
  #%x(gs -q -r150x150 -dNOPAUSE -sDEVICE=tiff32nc -sOutputFile=#{tiff_file_path} #{file_path} -c quit)
end



data = {}
Stop.all.to_a.each{|s|
  data[s.code] = [s.code,
                  s.name,
                  "http://www.openstreetmap.org/?mlat=#{s.latitude}&mlon=#{s.longitude}#map=17/#{s.latitude}/#{s.longitude}"
            ].concat(Route.through(s).map { |r|
              if (r.name.index('Нічний').nil?)
                result = r.name.slice(0, 4)
              else
                result = r.name.slice(0, 11)
              end
              result.tr('-', '')
            }.uniq.sort)
}
data = data.values.sort { |a, b| a[0] <=> b[0] }.map {|a| a.join(';') }.join("\n")
