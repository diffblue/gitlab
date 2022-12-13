# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a DAST Profile', feature_category: :dynamic_application_security_testing do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }
  let_it_be(:dast_profile_name) { SecureRandom.hex }

  let(:dast_profile) { Dast::Profile.find_by(project: project, name: dast_profile_name) }

  let(:mutation_name) { :dast_profile_create }

  let(:mutation) do
    graphql_mutation(
      mutation_name,
      full_path: full_path,
      name: dast_profile_name,
      branch_name: project.default_branch,
      dast_site_profile_id: global_id_of(dast_site_profile),
      dast_scanner_profile_id: global_id_of(dast_scanner_profile),
      run_after_create: true
    )
  end

  it_behaves_like 'an on-demand scan mutation when user cannot run an on-demand scan'

  it_behaves_like 'an on-demand scan mutation when user can run an on-demand scan' do
    it 'returns dastProfile.id' do
      subject

      expect(mutation_response['dastProfile']).to match a_graphql_entity_for(dast_profile)
    end

    it 'returns dastProfile.editPath' do
      subject

      expect(mutation_response.dig('dastProfile', 'editPath')).to eq(edit_project_on_demand_scan_path(project, dast_profile))
    end

    it 'returns a non-empty pipelineUrl' do
      subject

      expect(mutation_response['pipelineUrl']).not_to be_blank
    end

    context 'when dastProfileSchedule is present' do
      let(:mutation) do
        graphql_mutation(
          mutation_name,
          full_path: full_path,
          name: dast_profile_name,
          branch_name: project.default_branch,
          dast_site_profile_id: global_id_of(dast_site_profile),
          dast_scanner_profile_id: global_id_of(dast_scanner_profile),
          run_after_create: true,
          dast_profile_schedule: {
            starts_at: Time.zone.now,
            active: true,
            cadence: { duration: 1, unit: 'DAY' },
            timezone: 'America/New_York'
          }
        )
      end

      it 'creates a Dast::ProfileSchedule' do
        expect { subject }.to change { Dast::ProfileSchedule.count }.by(1)
      end
    end
  end
end
