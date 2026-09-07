module Routing
  module Engines
    # Clarke-Wright parallel savings with a 2-opt pass per route. Open routes:
    # the courier starts at the pickup and finishes at the last stop. Used when
    # vrp-cli is not installed, and in the test suite.
    class Savings < Engine
      def name
        "savings"
      end

      def solve(depot:, points:, max_stops:, start_at: nil)
        n = points.size
        return Solution.new(routes: [], unassigned: [], engine: name) if n.zero?

        from_depot = points.map { |p| Distance.km(depot.lat, depot.lng, p.lat, p.lng) }
        between = Array.new(n) { |i| Array.new(n) { |j| i == j ? 0.0 : Distance.km(points[i].lat, points[i].lng, points[j].lat, points[j].lng) } }

        routes = Array.new(n) { |i| [i] }
        route_of = (0...n).to_a

        savings = []
        (0...n).each do |i|
          ((i + 1)...n).each do |j|
            savings << [from_depot[i] + from_depot[j] - between[i][j], i, j]
          end
        end
        savings.sort_by! { |s, i, j| [-s, i, j] }

        savings.each do |_, i, j|
          ri = route_of[i]
          rj = route_of[j]
          next if ri == rj
          a = routes[ri]
          b = routes[rj]
          next if a.size + b.size > max_stops

          merged =
            if a.last == i && b.first == j then a + b
            elsif a.first == i && b.last == j then b + a
            elsif a.last == i && b.last == j then a + b.reverse
            elsif a.first == i && b.first == j then a.reverse + b
            end
          next unless merged

          routes[ri] = merged
          routes[rj] = nil
          merged.each { |k| route_of[k] = ri }
        end

        ordered = routes.compact.map { |r| two_opt(r, from_depot, between) }
        ordered.sort_by! { |r| from_depot[r.first] }
        Solution.new(routes: ordered.map { |r| r.map { |k| points[k].id } }, unassigned: [], engine: name)
      end

      private

      # Open-path 2-opt: the depot is fixed at the start, the end is free.
      def two_opt(route, from_depot, between)
        return route if route.size < 3
        best = route.dup
        improved = true
        while improved
          improved = false
          (0...(best.size - 1)).each do |i|
            ((i + 1)...best.size).each do |j|
              candidate = best[0...i] + best[i..j].reverse + best[(j + 1)..]
              if path_length(candidate, from_depot, between) + 1e-9 < path_length(best, from_depot, between)
                best = candidate
                improved = true
              end
            end
          end
        end
        best
      end

      def path_length(route, from_depot, between)
        total = from_depot[route.first]
        route.each_cons(2) { |a, b| total += between[a][b] }
        total
      end
    end
  end
end
