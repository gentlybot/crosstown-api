require "csv"

module Batches
  # Turns a batch's raw CSV into order rows, one per line, recording a list of
  # human-readable problems on each row that cannot go out as-is. The batch
  # ends up "ready" or "needs_review"; a file we cannot read at all raises.
  class CsvImporter
    class InvalidFile < StandardError; end

    HEADER_ALIASES = {
      "name" => "name", "recipient" => "name", "customer" => "name", "customer_name" => "name", "recipient_name" => "name",
      "phone" => "phone", "phone_number" => "phone", "telephone" => "phone", "mobile" => "phone",
      "email" => "email", "email_address" => "email",
      "address" => "address", "address_1" => "address", "address1" => "address", "street" => "address", "street_address" => "address",
      "unit" => "unit", "apt" => "unit", "apartment" => "unit", "suite" => "unit", "address_2" => "unit", "address2" => "unit", "buzzer" => "unit",
      "city" => "city", "town" => "city",
      "postal_code" => "postal_code", "postalcode" => "postal_code", "postcode" => "postal_code", "zip" => "postal_code", "zip_code" => "postal_code",
      "notes" => "notes", "note" => "notes", "instructions" => "notes", "delivery_notes" => "notes",
      "quantity" => "quantity", "qty" => "quantity", "packages" => "quantity", "items" => "quantity",
      "leave_at_door" => "leave_at_door", "leave_at_the_door" => "leave_at_door", "contactless" => "leave_at_door",
      "order_id" => "external_id", "order" => "external_id", "id" => "external_id", "reference" => "external_id", "order_number" => "external_id"
    }.freeze

    REQUIRED_HEADERS = %w[name address postal_code].freeze
    POSTAL_CODE = /\A[A-Z]\d[A-Z] ?\d[A-Z]\d\z/
    TRUTHY = %w[1 y yes true t x].freeze
    MAX_ROWS = 2_000

    def initialize(batch)
      @batch = batch
    end

    def call
      if RouteStop.joins(:order).where(orders: { batch_id: @batch.id }).exists?
        raise InvalidFile, "This batch already has routed orders and cannot be re-imported."
      end
      table = parse(@batch.raw_csv.to_s)
      check_headers!(table.headers)
      raise InvalidFile, "The file has a header row but no orders." if table.empty?
      raise InvalidFile, "The file has more than #{MAX_ROWS} rows. Split it into smaller batches." if table.size > MAX_ROWS

      Order.transaction do
        @batch.orders.delete_all
        table.each_with_index do |row, index|
          next if row.to_h.values.all?(&:blank?)
          @batch.orders.create!(build_order(row, index + 1))
        end
      end

      @batch.finish_import!
      @batch
    end

    private

    def parse(text)
      text = text.sub(/\A\xEF\xBB\xBF/, "") # strip a UTF-8 BOM from spreadsheet exports
      CSV.parse(text, headers: true, header_converters: ->(h) { normalize_header(h) }, skip_blanks: true)
    rescue CSV::MalformedCSVError => e
      raise InvalidFile, "That does not look like a CSV file (#{e.message})."
    end

    def normalize_header(header)
      key = header.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "")
      HEADER_ALIASES.fetch(key, key)
    end

    def check_headers!(headers)
      missing = REQUIRED_HEADERS - Array(headers).compact
      return if missing.empty?
      raise InvalidFile, "The file is missing required columns: #{missing.map(&:humanize).join(', ')}."
    end

    def build_order(row, row_number)
      attrs = {
        merchant: @batch.merchant,
        row_number: row_number,
        external_id: clean(row["external_id"]),
        recipient_name: clean(row["name"]),
        recipient_phone: clean(row["phone"]),
        recipient_email: clean(row["email"])&.downcase,
        address_line: clean(row["address"]),
        unit: clean(row["unit"]),
        city: clean(row["city"]).presence || @batch.merchant.pickup_city,
        postal_code: clean(row["postal_code"])&.upcase&.gsub(/\s+/, ""),
        notes: clean(row["notes"]),
        leave_at_door: TRUTHY.include?(clean(row["leave_at_door"]).to_s.downcase),
        quantity: 1
      }
      attrs[:postal_code] = attrs[:postal_code].insert(3, " ") if attrs[:postal_code]&.length == 6

      problems = []
      problems << "Name is missing" if attrs[:recipient_name].blank?
      problems << "Address is missing" if attrs[:address_line].blank?
      if attrs[:postal_code].blank?
        problems << "Postal code is missing"
      elsif !attrs[:postal_code].match?(POSTAL_CODE)
        problems << "Postal code does not look valid"
      end
      problems << "Phone or email is required" if attrs[:recipient_phone].blank? && attrs[:recipient_email].blank?
      if attrs[:recipient_email].present? && !attrs[:recipient_email].match?(URI::MailTo::EMAIL_REGEXP)
        problems << "Email does not look valid"
      end

      quantity = clean(row["quantity"])
      if quantity.present?
        if quantity.match?(/\A\d+\z/) && quantity.to_i >= 1
          attrs[:quantity] = quantity.to_i
        else
          problems << "Quantity must be a whole number of 1 or more"
        end
      end

      geocode!(attrs, problems)

      attrs[:problems] = problems
      attrs[:status] = problems.empty? ? "ready" : "problem"
      attrs
    end

    # Places the row against the address bank. A found address also checks the
    # postal code's forward sortation area, which catches the common typo of a
    # code from the wrong part of town.
    def geocode!(attrs, problems)
      return if attrs[:address_line].blank?

      hit = Geocoding::AddressBank.lookup(attrs[:address_line], city: attrs[:city])
      if hit.nil?
        attrs[:geocode_precision] = "none"
        problems << "Address not found"
        return
      end

      attrs[:lat] = hit.lat
      attrs[:lng] = hit.lng
      attrs[:fsa] = hit.fsa
      attrs[:geocode_precision] = hit.precision
      attrs[:geocoded_at] = Time.current

      given = attrs[:postal_code]
      if given.present? && given.match?(POSTAL_CODE) && given[0, 3] != hit.fsa
        problems << "Postal code #{given[0, 3]} does not match the address, which is in #{hit.fsa}"
      end
    end

    def clean(value)
      value.to_s.strip.presence
    end
  end
end
