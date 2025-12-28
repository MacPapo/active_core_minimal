module Avatarable
  extend ActiveSupport::Concern

  def initials
    return "NA" unless respond_to?(:first_name) && respond_to?(:last_name)

    f = first_name.to_s.strip.first
    l = last_name.to_s.strip.first
    "#{f}#{l}".upcase
  end

  def avatar_color_style
    hue = (id.to_i * 137) % 360
    "background-color: hsl(#{hue}, 70%, 85%); color: hsl(#{hue}, 80%, 30%); border-color: hsl(#{hue}, 60%, 80%);"
  end
end
