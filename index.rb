require 'rubygems'
require 'bundler/setup'
require 'active_support/all'

require 'json'
require 'nokogiri'

printf "#{Time.now.strftime('%d-%B %H:%M:%S')}\n"
code = ARGV[0]

API_LAD = "http://82.207.107.126:13541/SimpleRIDE/LAD/SM.WebApi/api/stops/?code=#{code}"
API_LET = "http://82.207.107.126:13541/SimpleRIDE/LET/SM.WebApi/api/stops/?code=#{code}"

data = []
[API_LAD, API_LET].each do |item|
    raw_data = %x(curl --silent "#{item}" -H "Accept: application/xml")

    n = Nokogiri::XML(raw_data)
    data.concat JSON.parse n.remove_namespaces!.xpath('//string').text
end

data.sort! { |a,b| a['TimeToPoint'] <=> b['TimeToPoint'] }

data.slice(0, 5).each do |item|
    printf "%-50s %s\n", item["RouteName"],  Time.at(item["TimeToPoint"]).utc.strftime("%Mm %Ss")
end