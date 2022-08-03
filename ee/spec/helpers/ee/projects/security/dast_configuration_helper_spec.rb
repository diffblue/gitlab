# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::DastConfigurationHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace, owner: user) }
  let_it_be(:project) { create(:project, :repository, namespace: namespace) }

  let(:security_configuration_path) { project_security_configuration_path(project) }
  let(:full_path) { project.full_path }
  let(:gitlab_ci_yaml_edit_path) { Rails.application.routes.url_helpers.project_ci_pipeline_editor_path(project) }
  let(:scanner_profiles_library_path) { project_security_configuration_profile_library_path(project, anchor: 'scanner-profiles') }
  let(:site_profiles_library_path) { project_security_configuration_profile_library_path(project, anchor: 'site-profiles') }
  let(:new_scanner_profile_path) { new_project_security_configuration_profile_library_dast_scanner_profile_path(project) }
  let(:new_site_profile_path) { new_project_security_configuration_profile_library_dast_site_profile_path(project) }
  let(:profile_name_included) { 'site_profile_name_included' }
  let(:scanner_profile_name_included) { 'scanner_profile_name_included' }

  describe '#dast_configuration_data' do
    subject { helper.dast_configuration_data(project, user) }

    context 'with yml_config_data' do
      before do
        service = instance_double(AppSec::Dast::ScanConfigs::FetchService)
        allow(AppSec::Dast::ScanConfigs::FetchService).to receive(:new).and_return(service)
        expect(service).to receive(:execute).and_return(result)
      end

      context 'when service does not return dast profile and scanner profile' do
        let(:result) { ServiceResponse.error(message: 'Dast configuration not found') }

        it {
          is_expected.to eq({
            security_configuration_path: security_configuration_path,
            full_path: full_path,
            gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
            scanner_profiles_library_path: scanner_profiles_library_path,
            site_profiles_library_path: site_profiles_library_path,
            new_scanner_profile_path: new_scanner_profile_path,
            new_site_profile_path: new_site_profile_path
          })
        }
      end

      context 'when service returns dast profile and scanner profile' do
        let(:result) do
          ServiceResponse.success(
            payload: { site_profile: profile_name_included, scanner_profile: scanner_profile_name_included }
          )
        end

        it {
          is_expected.to eq({
            security_configuration_path: security_configuration_path,
            full_path: full_path,
            gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
            scanner_profiles_library_path: scanner_profiles_library_path,
            site_profiles_library_path: site_profiles_library_path,
            new_scanner_profile_path: new_scanner_profile_path,
            new_site_profile_path: new_site_profile_path,
            site_profile: profile_name_included,
            scanner_profile: scanner_profile_name_included
          })
        }
      end
    end

    context 'with pipeline_data' do
      before do
        service = instance_double(AppSec::Dast::Pipelines::FindLatestService)
        allow(AppSec::Dast::Pipelines::FindLatestService).to receive(:new).and_return(service)
        expect(service).to receive(:execute).and_return(result)
      end

      context 'when pipeline data is present' do
        let(:pipeline) do
          create(
            :ci_pipeline,
            :auto_devops_source,
            project: project,
            ref: project.default_branch,
            sha: project.commit.sha,
            created_at: Time.now
          )
        end

        context 'when scanner is enabled' do
          let(:result) do
            ServiceResponse.success(
              payload: {
                latest_pipeline: pipeline
              }
            )
          end

          let!(:build_dast) { create(:ci_build, :dast, pipeline: pipeline, status: 'success') }

          it {
            is_expected.to eq({
              security_configuration_path: security_configuration_path,
              full_path: full_path,
              gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
              scanner_profiles_library_path: scanner_profiles_library_path,
              site_profiles_library_path: site_profiles_library_path,
              new_scanner_profile_path: new_scanner_profile_path,
              new_site_profile_path: new_site_profile_path,
              dast_enabled: true,
              pipeline_id: pipeline.id,
              pipeline_created_at: pipeline.created_at,
              pipeline_path: project_pipeline_path(project, pipeline)
            })
          }
        end

        context 'when scanner is not enabled' do
          let(:result) do
            ServiceResponse.success(
              payload: {}
            )
          end

          let!(:build_dast) { create(:ci_build, :dast, pipeline: pipeline, status: 'success') }

          it {
            is_expected.to eq({
              security_configuration_path: security_configuration_path,
              full_path: full_path,
              gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
              scanner_profiles_library_path: scanner_profiles_library_path,
              site_profiles_library_path: site_profiles_library_path,
              new_scanner_profile_path: new_scanner_profile_path,
              new_site_profile_path: new_site_profile_path,
              dast_enabled: false
            })
          }
        end
      end

      context 'when service returns an error' do
        let(:result) { ServiceResponse.error(message: 'Insufficient permissions') }

        it {
          is_expected.to eq({
            security_configuration_path: security_configuration_path,
            full_path: full_path,
            gitlab_ci_yaml_edit_path: gitlab_ci_yaml_edit_path,
            scanner_profiles_library_path: scanner_profiles_library_path,
            site_profiles_library_path: site_profiles_library_path,
            new_scanner_profile_path: new_scanner_profile_path,
            new_site_profile_path: new_site_profile_path
          })
        }
      end
    end
  end
end
