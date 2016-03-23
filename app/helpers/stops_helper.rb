module StopsHelper

  def stop_path(stop, options={})
    stop_url(stop, options)
  end

  def stop_url(stop, options={})
    url_for(options.merge(:controller => 'stops', :action => 'show',
                          :id => stop.code))
  end

end
