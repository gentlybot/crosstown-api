require "open3"
require "json"
require "tmpdir"

module Routing
  module Engines
    # Drives the vrp-cli solver (github.com/reinterpretcat/vrp) through its
    # pragmatic JSON format. No routing matrix is supplied, so the solver
    # approximates travel with straight-line distances, the same as the
    # fallback engine; what it adds is a proper metaheuristic search.
    class VrpCli < Engine
      DEFAULT_BINARY = Rails.root.join("vendor/vrp/bin/vrp-cli").to_s
      MAX_TIME_SECONDS = ENV.fetch("VRP_MAX_TIME", 6).to_i
      HARD_TIMEOUT_SECONDS = 60
      APPROX_SPEED_MPS = 6.0 # about 22 km/h, urban average with stops

      class SolverError < StandardError; end

      def self.binary
        candidates = [ENV["VRP_CLI_BIN"], DEFAULT_BINARY, *ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |d| File.join(d, "vrp-cli") }]
        candidates.compact.find { |path| File.executable?(path) }
      end

      def self.available?
        binary.present?
      end

      def name
        "vrp_cli"
      end

      def solve(depot:, points:, max_stops:, start_at:)
        return Solution.new(routes: [], unassigned: [], engine: name) if points.empty?
        binary = self.class.binary or raise SolverError, "vrp-cli is not installed"

        Dir.mktmpdir("crosstown-vrp") do |dir|
          problem_path = File.join(dir, "problem.json")
          solution_path = File.join(dir, "solution.json")
          File.write(problem_path, JSON.generate(problem(depot, points, max_stops, start_at)))

          cmd = [binary, "solve", "pragmatic", problem_path, "-o", solution_path, "--max-time", MAX_TIME_SECONDS.to_s, "--max-generations", "3000"]
          stdout, stderr, status = run(cmd)
          raise SolverError, "vrp-cli failed (#{status.exitstatus}): #{stderr.presence || stdout}".strip unless status.success? && File.exist?(solution_path)

          parse(JSON.parse(File.read(solution_path)), points)
        end
      end

      private

      def problem(depot, points, max_stops, start_at)
        vehicles = (points.size / max_stops.to_f).ceil + 1
        {
          plan: {
            jobs: points.map do |p|
              {
                id: "order-#{p.id}",
                deliveries: [{ places: [{ location: { lat: p.lat, lng: p.lng }, duration: p.service_seconds }], demand: [1] }]
              }
            end
          },
          fleet: {
            vehicles: [{
              typeId: "car",
              vehicleIds: (1..vehicles).map { |i| "car-#{i}" },
              profile: { matrix: "car" },
              # Fixed cost per vehicle pushes the solver to fill routes; distance in metres, time in seconds.
              costs: { fixed: 40.0, distance: 0.002, time: 0.004 },
              shifts: [{ start: { earliest: start_at.utc.iso8601, location: { lat: depot.lat, lng: depot.lng } } }],
              capacity: [max_stops]
            }],
            profiles: [{ name: "car", speed: APPROX_SPEED_MPS }]
          }
        }
      end

      def parse(solution, points)
        ids = points.map { |p| p.id.to_s }
        routes = Array(solution["tours"]).map do |tour|
          Array(tour["stops"]).flat_map do |stop|
            Array(stop["activities"]).select { |a| a["type"] == "delivery" }.map { |a| a["jobId"].delete_prefix("order-") }
          end
        end.reject(&:empty?)
        unassigned = Array(solution["unassigned"]).map { |u| u["jobId"].to_s.delete_prefix("order-") }
        # Give ids back in their original type.
        by_string = points.index_by { |p| p.id.to_s }
        routes = routes.map { |r| r.map { |id| by_string.fetch(id).id } }
        unassigned = unassigned.select { |id| ids.include?(id) }.map { |id| by_string.fetch(id).id }
        Solution.new(routes: routes, unassigned: unassigned, engine: name)
      end

      def run(cmd)
        Timeout.timeout(HARD_TIMEOUT_SECONDS) { Open3.capture3(*cmd) }
      rescue Timeout::Error
        raise SolverError, "vrp-cli did not finish within #{HARD_TIMEOUT_SECONDS}s"
      end
    end
  end
end
