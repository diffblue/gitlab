# frozen_string_literal: true

module Types
  module Sbom
    class PackageManagerEnum < BaseEnum
      graphql_name 'PackageManager'
      description 'Values for package manager'

      PACKAGE_MANAGERS = ::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES

      PACKAGE_MANAGERS.each do |package_manager|
        value package_manager.upcase,
          description: "Package manager: #{package_manager}.",
          value: package_manager
      end
    end
  end
end
