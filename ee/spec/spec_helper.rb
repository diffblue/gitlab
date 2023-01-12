# frozen_string_literal: true

require Rails.root.join("spec/support/helpers/stub_requests.rb")

Dir[Rails.root.join("ee/spec/support/helpers/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_contexts/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_examples/*.rb")].sort.each { |f| require f }
Dir[Rails.root.join("ee/spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include EE::LicenseHelpers

  config.define_derived_metadata(file_path: %r{ee/spec/}) do |metadata|
    # For now, we assign a starter license for ee/spec
    metadata[:with_license] = metadata.fetch(:with_license, true)

    location = metadata[:location]
    metadata[:geo] = metadata.fetch(:geo, true) if location =~ %r{[/_]geo[/_]}
  end

  config.define_derived_metadata do |metadata|
    # There's already a value, so do not set a default
    next if metadata.has_key?(:without_license)
    # There's already an opposing value, so do not set a default
    next if metadata.has_key?(:with_license)

    metadata[:without_license] = true
  end

  config.before(:context, :with_license) do
    License.destroy_all # rubocop: disable Cop/DestroyAll
    TestLicense.init
  end

  config.after(:context, :with_license) do
    License.destroy_all # rubocop: disable Cop/DestroyAll
  end

  config.before(:context, :without_license) do
    License.destroy_all # rubocop: disable Cop/DestroyAll
  end

  config.after(:context, :without_license) do
    TestLicense.init
  end

  config.around(:each, :geo_tracking_db) do |example|
    example.run if Gitlab::Geo.geo_database_configured?
  end
end
