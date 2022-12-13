# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a DAST Scanner Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, target_timeout: 200, spider_timeout: 5000) }
  let_it_be(:dast_scanner_profile_id) { global_id_of(dast_scanner_profile) }

  let(:new_profile_name) { SecureRandom.hex }
  let(:new_target_timeout) { dast_scanner_profile.target_timeout + 1 }
  let(:new_spider_timeout) { dast_scanner_profile.spider_timeout + 1 }
  let(:new_scan_type) { (DastScannerProfile.scan_types.keys - [DastScannerProfile.last.scan_type]).first }
  let(:new_use_ajax_spider) { !dast_scanner_profile.use_ajax_spider }
  let(:new_show_debug_messages) { !dast_scanner_profile.show_debug_messages }

  let(:mutation_name) { :dast_scanner_profile_update }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      id: dast_scanner_profile_id,
      profile_name: new_profile_name,
      target_timeout: new_target_timeout,
      spider_timeout: new_spider_timeout,
      scan_type: new_scan_type.upcase,
      use_ajax_spider: new_use_ajax_spider,
      show_debug_messages: new_show_debug_messages
    )
  end

  def mutation_response
    graphql_mutation_response(:dast_scanner_profile_update)
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns the dast_scanner_profile', :aggregate_failures do
      subject

      expect(mutation_response).to match a_graphql_entity_for(dast_scanner_profile)
      expect(mutation_response).to have_key('dastScannerProfile')

      profile = mutation_response['dastScannerProfile']
      expect(profile).to match a_graphql_entity_for(dast_scanner_profile, profile_name: new_profile_name)
    end

    it 'updates the dast_scanner_profile' do
      subject

      dast_scanner_profile = GlobalID.parse(mutation_response['id']).find

      aggregate_failures do
        expect(dast_scanner_profile.name).to eq(new_profile_name)
        expect(dast_scanner_profile.target_timeout).to eq(new_target_timeout)
        expect(dast_scanner_profile.spider_timeout).to eq(new_spider_timeout)
        expect(dast_scanner_profile.scan_type).to eq(new_scan_type)
        expect(dast_scanner_profile.use_ajax_spider).to eq(new_use_ajax_spider)
        expect(dast_scanner_profile.show_debug_messages).to eq(new_show_debug_messages)
      end
    end

    context 'when there is an issue updating the dast_scanner_profile' do
      let_it_be(:other_dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

      let(:new_profile_name) { other_dast_scanner_profile.name }

      it_behaves_like 'a mutation that returns errors in the response', errors: ['Name has already been taken']
    end

    context 'when the dast_scanner_profile does not exist' do
      let(:dast_scanner_profile_id) { Gitlab::GlobalId.build(nil, model_name: 'DastScannerProfile', id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end
end
