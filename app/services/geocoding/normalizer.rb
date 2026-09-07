module Geocoding
  # Turns "Queen Street West" and "queen st. w" into the same key.
  module Normalizer
    SUFFIXES = {
      "street" => "st", "st" => "st", "avenue" => "ave", "ave" => "ave", "av" => "ave", "road" => "rd", "rd" => "rd",
      "drive" => "dr", "dr" => "dr", "boulevard" => "blvd", "blvd" => "blvd", "crescent" => "cres", "cres" => "cres",
      "court" => "crt", "crt" => "crt", "ct" => "crt", "place" => "pl", "pl" => "pl", "lane" => "ln", "ln" => "ln",
      "trail" => "trl", "trl" => "trl", "terrace" => "terr", "terr" => "terr", "circle" => "cir", "cir" => "cir",
      "gardens" => "gdns", "gdns" => "gdns", "square" => "sq", "sq" => "sq", "parkway" => "pkwy", "pkwy" => "pkwy"
    }.freeze
    DIRECTIONS = { "west" => "w", "w" => "w", "east" => "e", "e" => "e", "north" => "n", "n" => "n", "south" => "s", "s" => "s" }.freeze

    def self.street(name)
      tokens = name.to_s.downcase.gsub(/[^a-z0-9 ]/, " ").split
      tokens.map! { |t| SUFFIXES.fetch(t, DIRECTIONS.fetch(t, t)) }
      tokens.join(" ")
    end
  end
end
