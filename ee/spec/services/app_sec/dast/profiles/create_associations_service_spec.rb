# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::Profiles::CreateAssociationsService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_projects: [project]) }
  let_it_be(:outsider) { create(:user) }
  let_it_be(:dast_site_profile) { create(:dast_site_profile, project: project) }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }

  let(:dast_site_profile_name) { dast_site_profile.name }
  let(:dast_scanner_profile_name) { dast_scanner_profile.name }

  let!(:pipeline) { create(:ci_pipeline, project: project, user: user) }
  let!(:stage) { create(:ci_stage, project: project, pipeline: pipeline, name: :dast) }

  let!(:dast_build) do
    create(
      :ci_build,
      project: project,
      user: user,
      pipeline: pipeline,
      stage_id: stage.id,
      options: {
        dast_configuration: {
          site_profile: dast_site_profile_name,
          scanner_profile: dast_scanner_profile_name
        }
      }
    )
  end

  let(:params) { { builds: [dast_build] } }

  subject { described_class.new(project: project, current_user: user, params: params).execute }

  describe '#execute' do
    context 'when the feature is licensed' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
        subject
      end

      context 'when the user cannot create dast scans' do
        let_it_be(:user) { outsider }

        it_behaves_like 'an error occurred during the dast profile association' do
          let(:error_message) { 'Insufficient permissions for dast_configuration keyword' }
        end
      end

      context 'dast_site_profile' do
        let(:profile) { dast_site_profile }

        it_behaves_like 'it attempts to associate the profile', :dast_site_profile_name
      end

      context 'dast_scanner_profile' do
        let(:profile) { dast_scanner_profile }

        it_behaves_like 'it attempts to associate the profile', :dast_scanner_profile_name
      end

      context 'when the user cannot create dast scans' do
        let_it_be(:user) { outsider }

        it_behaves_like 'an error occurred during the dast profile association' do
          let(:error_message) { 'Insufficient permissions for dast_configuration keyword' }
        end
      end

      context 'when the build has multiple dast_configurations' do
        let(:dast_site_profile_2) do
          create(:dast_site_profile, project: custom_project, name: dast_site_profile_2_name)
        end

        let(:dast_scanner_profile_2) do
          create(:dast_scanner_profile, project: custom_project, name: dast_scanner_profile_2_name)
        end

        let!(:dast_build_2) do
          create(
            :ci_build,
            project: project,
            user: user,
            pipeline: pipeline,
            stage_id: stage.id,
            options: {
              dast_configuration: {
                site_profile: dast_site_profile_2.name,
                scanner_profile: dast_scanner_profile_2.name
              }
            }
          )
        end

        let(:builds) { [dast_build, dast_build_2] }
        let(:params) { { builds: builds } }

        context 'with different name and same project' do
          let(:dast_scanner_profile_2_name) { 'test' }
          let(:dast_site_profile_2_name) { 'test' }
          let(:custom_project) { project }
          let(:expected_associations) do
            {
              dast_build => {
                dast_site_profile: dast_site_profile,
                dast_scanner_profile: dast_scanner_profile
              },
              dast_build_2 => {
                dast_site_profile: dast_site_profile_2,
                dast_scanner_profile: dast_scanner_profile_2
              }
            }
          end

          it 'associate the associations correctly', :aggregate_failures do
            expected_associations.each do |build, associations|
              associations.each do |association_name, association|
                expect(build.public_send(association_name)).to eq(association)
              end
            end
          end
        end

        context 'with same named profiles from different project' do
          let(:dast_scanner_profile_2_name) { dast_scanner_profile.name }
          let(:dast_site_profile_2_name) { dast_site_profile.name }
          let(:custom_project) { create(:project) }
          let(:expected_associations) do
            {
              dast_build => {
                dast_site_profile: dast_site_profile,
                dast_scanner_profile: dast_scanner_profile
              }
            }
          end

          it 'associate the associations correctly', :aggregate_failures do
            expected_associations.each do |build, associations|
              associations.each do |association_name, association|
                expect(build.public_send(association_name)).to eq(association)
              end
            end
          end
        end
      end
    end

    context 'when not licensed' do
      before do
        stub_licensed_features(security_on_demand_scans: false)
      end

      let(:error_message) { 'Insufficient permissions for dast_configuration keyword' }

      it_behaves_like 'an error occurred during the dast profile association' do
        let(:error_message) { 'Insufficient permissions for dast_configuration keyword' }
      end
    end
  end
end
