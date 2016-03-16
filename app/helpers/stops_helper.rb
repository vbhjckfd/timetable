module StopsHelper

  def strip_route(title)
    title.gsub(/\D/, '')
  end

  def image_url(type)
    case type
      when :bus
        'https://cdn4.iconfinder.com/data/icons/dot/64/bus.png'
      when :tram
        'https://cdn4.iconfinder.com/data/icons/aiga-symbol-signs/475/aiga_railtransportion-64.png'
      when :trol
        'https://cdn2.iconfinder.com/data/icons/windows-8-metro-style/64/trolleybus.png'
    end
  end

  def round_time(time)
    time = Time.at(time).utc
    return '< 1 хв' if time.to_i < 31

    disp_time = time + (time.sec > 30 ? 1 : 0).minute
    disp_time.strftime("%-M хв")
  end
  
end
