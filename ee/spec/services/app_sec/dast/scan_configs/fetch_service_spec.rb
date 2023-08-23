# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ScanConfigs::FetchService, feature_category: :dynamic_application_security_testing do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace, owner: user) }

  let_it_be(:project) do
    gitlab_ci_yml = File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_dast_includes.yml'))

    create(:project, :custom_repo, namespace: namespace, files: { '.gitlab-ci.yml' => gitlab_ci_yml })
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  let(:profile_name_included) { 'site_profile_name_included' }
  let(:profile_name_policy) { 'Site Profile' }
  let(:scanner_profile_name_included) { 'scanner_profile_name_included' }
  let(:scanner_profile_name_policy) { 'Scanner Profile' }

  shared_examples 'an error occurred' do
    it 'communicates failure', :aggregate_failures do
      expect(subject).to be_error
      expect(subject.errors).to include(error_message)
    end
  end

  describe '#execute' do
    subject { described_class.new(project: project, current_user: user).execute }

    context 'when site profile and scanner profile is not configured in ci yml file' do
      let_it_be(:project) do
        gitlab_ci_yml = File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))

        create(:project, :custom_repo, namespace: namespace, files: { '.gitlab-ci.yml' => gitlab_ci_yml })
      end

      it_behaves_like 'an error occurred' do
        let(:error_message) { 'DAST configuration not found' }
      end
    end

    context 'when site profile and scanner profile is configured in ci yml file' do
      context 'with an invalid .gitlab-ci.yml' do
        let_it_be(:project) do
          create(:project, :custom_repo, namespace: namespace, files: { '.gitlab-ci.yml' => 'invalid' })
        end

        it_behaves_like 'an error occurred' do
          let(:error_message) { "Invalid configuration format" }
        end
      end

      context 'with a valid .gitlab-ci.yml' do
        let(:payload) do
          {
            site_profile: profile_name_included,
            scanner_profile: scanner_profile_name_included
          }
        end

        it 'returns configured profile values' do
          expect(subject.payload).to eq payload
        end
      end
    end

    context 'when site profile and scanner profile is configured in security policy' do
      let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline') }

      let(:policy_yaml) do
        build(:orchestration_policy_yaml, scan_execution_policy: [policy])
      end

      let(:policy_management_project) do
        create(
          :project, :custom_repo,
          namespace: namespace,
          files: { '.gitlab/security-policies/policy.yml' => policy_yaml })
      end

      let(:policy_configuration) do
        create(
          :security_orchestration_policy_configuration,
          security_policy_management_project: policy_management_project,
          project: project
        )
      end

      before do
        policy_configuration
        stub_licensed_features(security_orchestration_policies: true, security_on_demand_scans: true)
      end

      let(:payload) do
        {
          site_profile: profile_name_policy,
          scanner_profile: scanner_profile_name_policy
        }
      end

      context 'and site profile and scanner profile is configured in ci yml file' do
        it 'returns configured profile values from policy' do
          expect(subject.payload).to eq payload
        end
      end

      context 'and site profile and scanner profile is not configured in ci yml file' do
        let_it_be(:project) do
          gitlab_ci_yml = File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))

          create(:project, :custom_repo, namespace: namespace, files: { '.gitlab-ci.yml' => gitlab_ci_yml })
        end

        it 'returns configured profile values from policy' do
          expect(subject.payload).to eq payload
        end

        context 'and when profile data is missing' do
          let(:actions) { [{ scan: 'dast' }] }

          let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline', actions: actions) }

          it_behaves_like 'an error occurred' do
            let(:error_message) { 'DAST configuration not found' }
          end
        end

        context 'and when multiple actions are there' do
          let(:actions) do
            [
              { scan: 'dast', site_profile: profile_name_policy, scanner_profile: scanner_profile_name_policy },
              { scan: 'dast', site_profile: "profile 2", scanner_profile: "scanner 2" }
            ]
          end

          let(:policy) { build(:scan_execution_policy, name: 'Run DAST in every pipeline', actions: actions) }

          let(:payload) do
            {
              site_profile: profile_name_policy,
              scanner_profile: scanner_profile_name_policy
            }
          end

          it 'returns the correct action' do
            expect(subject.payload).to eq payload
          end
        end
      end
    end

    context 'when on demand scan licensed feature is not available' do
      before do
        stub_licensed_features(security_on_demand_scans: false)
      end

      it_behaves_like 'an error occurred' do
        let(:error_message) { 'Insufficient permissions' }
      end
    end
  end
end
