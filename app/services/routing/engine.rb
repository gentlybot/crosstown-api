module Routing
  # Common interface for anything that can turn points into routes. The
  # original app swapped between three vendors behind a shape like this; here
  # the real solver is vrp-cli and the fallback is a Ruby heuristic.
  class Engine
    NAMES = %w[vrp_cli savings].freeze

    def self.default
      self.for(ENV.fetch("ROUTING_ENGINE", "auto"))
    end

    def self.for(name)
      case name.to_s
      when "vrp_cli" then Engines::VrpCli.new
      when "savings" then Engines::Savings.new
      when "auto", "" then Engines::VrpCli.available? ? Engines::VrpCli.new : Engines::Savings.new
      else raise ArgumentError, "Unknown routing engine #{name.inspect}. Known: #{NAMES.join(', ')}."
      end
    end

    def name
      raise NotImplementedError
    end

    # @return [Routing::Solution]
    def solve(depot:, points:, max_stops:, start_at:)
      raise NotImplementedError
    end
  end
end
