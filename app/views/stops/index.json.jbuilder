json.array!(@stops) do |stop|
  json.extract! stop, :id, :name, :longitude, :latitude, :id, :code
  json.url stop_url(stop, format: :json)
end
