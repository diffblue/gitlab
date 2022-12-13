# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a DAST Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project) }

  let(:mutation_name) { :dast_profile_update }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      id: global_id_of(dast_profile),
      name: 'updated dast_profiles.name',
      branch_name: project.default_branch,
      run_after_update: true
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns a non-nil dastProfile' do
      subject

      expect(mutation_response['dastProfile']).not_to be_nil
    end

    it 'returns a non-nil pipelineUrl' do
      subject

      expect(mutation_response['pipelineUrl']).not_to be_nil
    end

    it 'updates the dast_profile' do
      expect { subject }.to change { dast_profile.reload.name }.to('updated dast_profiles.name')
    end

    context 'when updating fails' do
      it 'returns an error' do
        allow_next_instance_of(::AppSec::Dast::Profiles::UpdateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Profile failed to update')
          )
        end

        subject

        expect(mutation_response['errors']).to include('Profile failed to update')
      end
    end
  end
end
