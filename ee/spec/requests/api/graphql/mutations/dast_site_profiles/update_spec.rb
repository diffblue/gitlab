# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile_id) { global_id_of(dast_site_profile) }

  let_it_be(:new_profile_name) { SecureRandom.hex }
  let_it_be(:new_target_url) { generate(:url) }

  let(:mutation_name) { :dast_site_profile_update }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      id: dast_site_profile_id,
      profile_name: new_profile_name,
      target_url: new_target_url,
      target_type: 'API',
      scan_method: 'OPENAPI',
      scan_file_path: 'https://www.domain.com/test-api-specification.json',
      excluded_urls: ["#{new_target_url}/signout"],
      request_headers: 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0',
      auth: {
        enabled: true,
        url: "#{new_target_url}/login",
        username_field: 'session[username]',
        password_field: 'session[password]',
        submit_field: 'css:button[type="submit"]',
        username: generate(:email),
        password: SecureRandom.hex
      }
    )
  end

  def mutation_response
    graphql_mutation_response(mutation_name)
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'updates the dast_site_profile' do
      subject

      dast_site_profile = GlobalID.parse(mutation_response['id']).find

      aggregate_failures do
        expect(dast_site_profile.name).to eq(new_profile_name)
        expect(dast_site_profile.dast_site.url).to eq(new_target_url)
      end
    end

    context 'when there is a validation error' do
      before do
        allow(dast_site_profile).to receive(:valid?).and_return(false)
        allow(dast_site_profile).to receive_message_chain(:errors, :full_messages).and_return(['There was a validation error'])

        allow_next_instance_of(DastSiteProfilesFinder) do |instance|
          allow(instance).to receive_message_chain(:execute, :first!).and_return(dast_site_profile)
        end
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['There was a validation error']
    end

    context 'when the dast_site_profile does not exist' do
      let_it_be(:dast_site_profile_id) { Gitlab::GlobalId.build(nil, model_name: 'DastSiteProfile', id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when wrong type of global id is passed' do
      let_it_be(:dast_site_profile_id) { global_id_of(project) }

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          eq(["Variable $dastSiteProfileUpdateInput of type DastSiteProfileUpdateInput! " \
              "was provided invalid value for id (\"#{dast_site_profile_id}\" does not represent an instance " \
              "of DastSiteProfile)"])
        end
      end
    end
  end
end
