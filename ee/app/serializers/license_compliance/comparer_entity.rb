# frozen_string_literal: true

module LicenseCompliance
  class ComparerEntity < Grape::Entity
    expose :new_licenses, using: ::Security::LicensePolicyEntity
    expose :existing_licenses, using: ::Security::LicensePolicyEntity
    expose :removed_licenses, using: ::Security::LicensePolicyEntity
  end
end
