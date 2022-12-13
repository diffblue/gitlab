# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete a DAST Scanner Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let_it_be(:dast_scanner_profile_id) { global_id_of(dast_scanner_profile) }

  let(:mutation_name) { :dast_scanner_profile_delete }

  let(:mutation) do
    graphql_mutation(mutation_name, id: dast_scanner_profile_id)
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'
  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'deletes the dast_scanner_profile' do
      expect { subject }.to change { DastScannerProfile.count }.by(-1)
    end

    context 'when the dast_scanner_profile does not exist' do
      let(:dast_scanner_profile_id) { Gitlab::GlobalId.build(nil, model_name: 'DastScannerProfile', id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end
end
