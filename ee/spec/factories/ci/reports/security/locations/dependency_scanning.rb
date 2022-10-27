# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_locations_dependency_scanning, class: '::Gitlab::Ci::Reports::Security::Locations::DependencyScanning' do
    file_path { 'app/pom.xml' }
    package_name { 'io.netty/netty' }
    package_version { '1.2.3' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Locations::DependencyScanning.new(**attributes)
    end
  end
end
