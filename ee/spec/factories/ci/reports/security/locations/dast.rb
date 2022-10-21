# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_security_locations_dast, class: '::Gitlab::Ci::Reports::Security::Locations::Dast' do
    hostname { 'my-app.com' }
    method_name { 'GET' }
    param { 'X-Content-Type-Options' }
    path { '/some/path' }

    skip_create

    initialize_with do
      ::Gitlab::Ci::Reports::Security::Locations::Dast.new(**attributes)
    end
  end
end
