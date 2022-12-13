# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:profile_name) { FFaker::Company.catch_phrase }
  let_it_be(:target_url) { generate(:url) }

  let(:mutation_name) { :dast_site_profile_create }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      profile_name: profile_name,
      target_url: target_url,
      target_type: 'API',
      scan_method: 'OPENAPI',
      scan_file_path: 'https://www.domain.com/test-api-specification.json',
      excluded_urls: ["#{target_url}/logout"],
      request_headers: 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0',
      auth: {
        enabled: true,
        url: "#{target_url}/login",
        username_field: 'session[username]',
        password_field: 'session[password]',
        submit_field: 'css:button[type="submit"]',
        username: generate(:email),
        password: SecureRandom.hex
      }
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns the dast_site_profile id' do
      subject

      dast_site_profile = DastSiteProfile.find_by(project: project, name: profile_name)

      expect(mutation_response).to match(a_graphql_entity_for(dast_site_profile))
    end
  end
end
