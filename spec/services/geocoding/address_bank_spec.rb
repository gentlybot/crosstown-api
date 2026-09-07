require "rails_helper"

RSpec.describe Geocoding::AddressBank do
  describe ".parse" do
    it "splits number and street and normalizes the street" do
      expect(described_class.parse("300 Queen Street West")).to have_attributes(number: 300, street: "queen st w")
      expect(described_class.parse("300 queen st. w, Toronto, ON M5V 2A2")).to have_attributes(number: 300, street: "queen st w")
      expect(described_class.parse("Unit 4, 22 Palmerston Avenue")).to have_attributes(number: 22, street: "palmerston ave")
      expect(described_class.parse("22A Palmerston Ave")).to have_attributes(number: 22, street: "palmerston ave")
      expect(described_class.parse("22-24 Palmerston Ave")).to have_attributes(number: 22, street: "palmerston ave")
    end

    it "gives up without a civic number" do
      expect(described_class.parse("Palmerston Ave")).to be_nil
      expect(described_class.parse("")).to be_nil
    end
  end

  describe ".lookup" do
    it "finds an exact civic number" do
      hit = described_class.lookup("22 Palmerston Ave")
      expect(hit.precision).to eq("exact")
      expect(hit.fsa).to eq("M6J")
      expect(hit.street_display).to eq("Palmerston Ave")
    end

    it "picks the right segment of a long street" do
      expect(described_class.lookup("300 Queen St W").fsa).to eq("M5V")
      expect(described_class.lookup("1200 Queen Street West").fsa).to eq("M6J")
      expect(described_class.lookup("1122 Danforth Ave").fsa).to eq("M4J")
    end

    it "interpolates a missing number between neighbours" do
      AddressBankEntry.where(street_name: "palmerston ave", street_number: 23).delete_all
      hit = described_class.lookup("23 Palmerston Ave")
      expect(hit.precision).to eq("interpolated")
      lower = AddressBankEntry.find_by!(street_name: "palmerston ave", street_number: 21)
      upper = AddressBankEntry.find_by!(street_name: "palmerston ave", street_number: 25)
      expect(hit.lat).to be_between([lower.lat, upper.lat].min, [lower.lat, upper.lat].max)
    end

    it "snaps a number just past the end of the street" do
      expect(described_class.lookup("640 Palmerston Ave").precision).to eq("approximate")
      expect(described_class.lookup("900 Palmerston Ave")).to be_nil
    end

    it "prefers the requested city when the street exists there" do
      expect(described_class.lookup("600 Bloor St W", city: "Toronto").fsa).to eq("M6G")
      expect(described_class.lookup("3000 Bloor St W", city: "Toronto").fsa).to eq("M8X")
      expect(described_class.lookup("200 Hurontario St", city: "Mississauga").city).to eq("Mississauga")
    end

    it "returns nil for unknown streets" do
      expect(described_class.lookup("1 Nowhere Cres")).to be_nil
    end
  end
end
