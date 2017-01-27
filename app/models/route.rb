class Route < ActiveRecord::Base
  has_and_belongs_to_many :stops

  def self.through(stop)
    self.joins(:stops).where('stops.code = ?', stop.code).uniq
  end
end
