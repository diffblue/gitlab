# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Site Profile' do
  include GraphqlHelpers

  let!(:dast_site_profile) { create(:dast_site_profile, project: project) }

  let(:new_profile_name) { SecureRandom.hex }
  let(:new_target_url) { generate(:url) }

  let(:mutation_name) { :dast_site_profile_update }
  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      id: dast_site_profile.to_global_id.to_s,
      profile_name: new_profile_name,
      target_url: new_target_url,
      target_type: 'API',
      excluded_urls: ["#{new_target_url}/signout"],
      request_headers: 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0',
      auth: {
        enabled: true,
        url: "#{new_target_url}/login",
        username_field: 'session[username]',
        password_field: 'session[password]',
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
      before do
        dast_site_profile.destroy!
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['DastSiteProfile not found']
    end

    context 'when wrong type of global id is passed' do
      let(:mutation) do
        graphql_mutation(
          mutation_name,
          full_path: full_path,
          id: dast_site_profile.dast_site.to_global_id.to_s,
          profile_name: new_profile_name,
          target_url: new_target_url
        )
      end

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          gid = dast_site_profile.dast_site.to_global_id

          eq(["Variable $dastSiteProfileUpdateInput of type DastSiteProfileUpdateInput! " \
              "was provided invalid value for id (\"#{gid}\" does not represent an instance " \
              "of DastSiteProfile)"])
        end
      end
    end

    context 'when the dast_site_profile belongs to a different project' do
      let(:mutation) do
        graphql_mutation(
          mutation_name,
          full_path: create(:project).full_path,
          id: dast_site_profile.to_global_id.to_s,
          profile_name: new_profile_name,
          target_url: new_target_url
        )
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end
  end
end
