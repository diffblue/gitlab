# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_locations_container_scanning, class: '::Gitlab::Ci::Reports::Security::Locations::ContainerScanning' do
    image { 'registry.gitlab.com/my/project:latest' }
    operating_system { 'debian:9' }
    package_name { 'glibc' }
    package_version { '1.2.3' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Locations::ContainerScanning.new(**attributes)
    end
  end
end
