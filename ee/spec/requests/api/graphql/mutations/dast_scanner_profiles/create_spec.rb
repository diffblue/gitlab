# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Scanner Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:profile_name) { FFaker::Company.catch_phrase }

  let(:dast_scanner_profile) { DastScannerProfile.find_by(project: project, name: profile_name) }

  let(:mutation_name) { :dast_scanner_profile_create }
  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      profile_name: profile_name
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns the dast_scanner_profile id' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to match a_graphql_entity_for(dast_scanner_profile)
      expect(mutation_response).to have_key('dastScannerProfile')

      profile = mutation_response['dastScannerProfile']
      expect(profile).to match a_graphql_entity_for(dast_scanner_profile)
      expect(profile['profileName']).to eq(dast_scanner_profile.name)
    end

    it 'sets default values of omitted properties' do
      post_graphql_mutation(mutation, current_user: current_user)

      aggregate_failures do
        expect(dast_scanner_profile.scan_type).to eq('passive')
        expect(dast_scanner_profile.use_ajax_spider).to eq(false)
        expect(dast_scanner_profile.show_debug_messages).to eq(false)
      end
    end

    context 'when dast_scanner_profile exists' do
      before do
        DastScannerProfile.create!(project: project, name: profile_name)
      end

      it 'returns errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to include('Name has already been taken')
      end
    end
  end
end
