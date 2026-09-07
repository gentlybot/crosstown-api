# One known civic address with coordinates. The bank is seeded, not fetched:
# the demo runs with no network access, so geocoding is a lookup against this
# table. See lib/address_bank for the seed streets.
class AddressBankEntry < ApplicationRecord
  validates :street_number, :street_name, :street_display, :city, :fsa, :lat, :lng, presence: true
end
