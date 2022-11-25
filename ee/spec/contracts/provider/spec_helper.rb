# frozen_string_literal: true

require Rails.root.join("config/initializers/0_inject_enterprise_edition_module.rb")
require Rails.root.join("ee/spec/support/helpers/ee/license_helpers.rb")
require Rails.root.join("spec/support/helpers/license_helper.rb")

Pact.configure do |config|
  config.include LicenseHelpers
end
