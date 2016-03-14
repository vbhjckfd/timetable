module Api::StopHelper

  def strip_route(title)
    title.sub(/^ЛАД /, '')
  end

  def round_time(time)
    return '< 1 хв' if time.to_i < 31

    disp_time = time + (time.sec > 30 ? 1 : 0).minute
    disp_time.strftime("%-M хв")
  end

end
