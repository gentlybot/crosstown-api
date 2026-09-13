module Demo
  # Merchant identities from crosstown-mcp's business scenario v1.0.0. The
  # fixture maps MCP customer IDs to app slugs; billing and usage stay in MCP.
  module MerchantSeed
    PASSWORD = "crosstown-demo"
    MERCHANTS = JSON.parse(Rails.root.join("db/seeds/merchants.json").read, symbolize_names: true).freeze
    LEGACY_USERS = [
      { email: "maya@bloomandstem.example", name: "Maya Chen", role: "merchant_admin", slug: "bloom-and-stem" },
      { email: "sam@bloomandstem.example", name: "Sam Whitfield", role: "merchant_staff", slug: "bloom-and-stem" },
      { email: "devin@cornerloaf.example", name: "Devin Osei", role: "merchant_admin", slug: "corner-loaf" }
    ].freeze

    def self.call
      Merchant.transaction do
        MERCHANTS.each do |attrs|
          Merchant.find_or_initialize_by(slug: attrs.fetch(:slug))
            .update!(attrs.except(:mcp_customer_id, :segment))
        end

        # Keep the original admins first on fresh databases: the allowance
        # demos select the oldest admin to own their reservation history.
        LEGACY_USERS.each { |attrs| seed_user(**attrs) }
        MERCHANTS.each do |attrs|
          seed_user(email: attrs.fetch(:contact_email), name: attrs.fetch(:contact_name),
            role: "merchant_admin", slug: attrs.fetch(:slug))
        end
      end
      MERCHANTS.size
    end

    def self.seed_user(email:, name:, role:, slug:)
      user = User.find_or_initialize_by(email: email)
      user.assign_attributes(name: name, role: role, merchant: Merchant.find_by!(slug: slug))
      user.password = PASSWORD if user.new_record?
      user.save!
    end
    private_class_method :seed_user
  end
end
