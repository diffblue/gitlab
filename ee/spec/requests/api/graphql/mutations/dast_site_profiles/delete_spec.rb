# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deleting a DAST Site Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_site_profile_id) { global_id_of(dast_site_profile) }

  let(:mutation_name) { :dast_site_profile_delete }

  let(:mutation) do
    graphql_mutation(mutation_name, id: dast_site_profile_id)
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'deletes the dast_site_profile' do
      expect { subject }.to change { DastSiteProfile.count }.by(-1)
    end

    context 'when there is an issue deleting the dast_site_profile' do
      before do
        allow_next_instance_of(::AppSec::Dast::SiteProfiles::DestroyService) do |service|
          allow(service).to receive(:execute).and_return(double(success?: false, errors: ['Name is weird']))
        end
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['Name is weird']
    end

    context 'when the dast_site_profile does not exist' do
      let_it_be(:dast_site_profile_id) { Gitlab::GlobalId.build(nil, model_name: 'DastSiteProfile', id: non_existing_record_id) }

      it_behaves_like 'a mutation that returns top-level errors', errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end

    context 'when wrong type of global id is passed' do
      let_it_be(:dast_site_profile_id) { global_id_of(dast_site_profile.dast_site) }

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) do
          eq(["Variable $dastSiteProfileDeleteInput of type DastSiteProfileDeleteInput! " \
              "was provided invalid value for id (\"#{dast_site_profile_id}\" does not represent an instance " \
              "of DastSiteProfile)"])
        end
      end
    end
  end
end
