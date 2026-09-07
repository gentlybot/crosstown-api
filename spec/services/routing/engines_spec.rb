require "rails_helper"

RSpec.describe "Routing engines" do
  let(:depot) { Routing::Point.new(id: "pickup", lat: 43.6472, lng: -79.4046) }
  let(:points) do
    # Two clusters, west and east of the depot.
    west = 6.times.map { |i| Routing::Point.new(id: "w#{i}", lat: 43.6450 + i * 0.0015, lng: -79.4180 - i * 0.0004) }
    east = 6.times.map { |i| Routing::Point.new(id: "e#{i}", lat: 43.6560 + i * 0.0015, lng: -79.3400 + i * 0.0004) }
    west + east
  end

  shared_examples "a routing engine" do
    it "visits every point once within the stop limit" do
      solution = engine.solve(depot: depot, points: points, max_stops: 8, start_at: Time.zone.parse("2026-09-09 14:00"))
      visited = solution.routes.flatten
      expect(visited.sort).to eq(points.map(&:id).sort)
      expect(solution.routes.map(&:size).max).to be <= 8
      expect(solution.unassigned).to be_empty
    end

    it "keeps the two clusters on separate routes" do
      solution = engine.solve(depot: depot, points: points, max_stops: 8, start_at: Time.zone.parse("2026-09-09 14:00"))
      mixed = solution.routes.count { |r| r.any? { |id| id.start_with?("w") } && r.any? { |id| id.start_with?("e") } }
      expect(mixed).to eq(0)
    end
  end

  describe Routing::Engines::Savings do
    let(:engine) { described_class.new }
    include_examples "a routing engine"

    it "handles an empty problem" do
      expect(engine.solve(depot: depot, points: [], max_stops: 8, start_at: Time.current).routes).to eq([])
    end
  end

  describe Routing::Engines::VrpCli, if: Routing::Engines::VrpCli.available? do
    let(:engine) { described_class.new }
    include_examples "a routing engine"
  end

  describe Routing::Engine do
    it "falls back to savings when vrp-cli is missing" do
      allow(Routing::Engines::VrpCli).to receive(:available?).and_return(false)
      expect(described_class.for("auto")).to be_a(Routing::Engines::Savings)
    end

    it "rejects unknown names" do
      expect { described_class.for("teleport") }.to raise_error(ArgumentError, /Unknown routing engine/)
    end
  end
end
