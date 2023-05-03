# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ScanConfigs::BuildService, :dynamic_analysis, feature_category: :dynamic_application_security_testing do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be_with_reload(:dast_site_profile) { create(:dast_site_profile, :with_dast_submit_field, project: project, target_type: 'website') }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project, spider_timeout: 5, target_timeout: 20) }
  let_it_be(:dast_profile) { create(:dast_profile, project: project, dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch_name: 'master') }

  let(:dast_website) { dast_site_profile.dast_site.url }
  let(:dast_exclude_urls) { dast_site_profile.excluded_urls.join(',') }
  let(:dast_auth_url) { dast_site_profile.auth_url }
  let(:dast_username) { dast_site_profile.auth_username }
  let(:dast_username_field) { dast_site_profile.auth_username_field }
  let(:dast_submit_field) { dast_site_profile.auth_submit_field }
  let(:dast_password_field) { dast_site_profile.auth_password_field }
  let(:dast_spider_mins) { dast_scanner_profile.spider_timeout }
  let(:dast_target_availability_timeout) { dast_scanner_profile.target_timeout }
  let(:dast_full_scan_enabled) { dast_scanner_profile.active? }
  let(:dast_use_ajax_spider) { dast_scanner_profile.use_ajax_spider? }
  let(:dast_debug) { dast_scanner_profile.show_debug_messages? }
  let(:on_demand_scan_template) { 'Security/DAST-On-Demand-Scan.gitlab-ci.yml' }
  let(:api_scan_template) { 'Security/DAST-On-Demand-API-Scan.gitlab-ci.yml' }

  let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile } }

  let(:expected_yaml_configuration) do
    <<~YAML
      ---
      stages:
      - dast
      include:
      - template: #{template}
      dast:
        dast_configuration:
          site_profile: #{dast_site_profile.name}
          scanner_profile: #{dast_scanner_profile.name}
    YAML
  end

  subject { described_class.new(container: project, params: params).execute }

  describe 'execute' do
    shared_examples 'build service execute tests' do
      context 'when a dast_profile is provided' do
        let(:params) { { dast_profile: dast_profile } }
        let(:expected_payload) do
          {
            dast_profile: dast_profile,
            branch: dast_profile.branch_name,
            ci_configuration: expected_yaml_configuration
          }
        end

        shared_examples 'a payload with a dast_profile' do
          it 'returns a branch and YAML configuration' do
            expected_payload = {
              dast_profile: dast_profile,
              branch: dast_profile.branch_name,
              ci_configuration: expected_yaml_configuration
            }

            expect(subject.payload).to eq(expected_payload)
          end
        end

        it 'returns a dast_profile, branch and YAML configuration' do
          expect(subject.payload).to eq(expected_payload)
        end

        context 'when the dast_profile has tag_list' do
          context 'when feature flag on_demand_scans_runner_tags is disabled' do
            before do
              stub_feature_flags(on_demand_scans_runner_tags: false)
            end

            it_behaves_like 'a payload with a dast_profile'
          end

          context 'when feature flag on_demand_scans_runner_tags is enabled' do
            let_it_be(:tags) { [ActsAsTaggableOn::Tag.create!(name: 'ruby'), ActsAsTaggableOn::Tag.create!(name: 'postgres')] }
            let_it_be(:dast_profile) do
              create(
                :dast_profile,
                project: project,
                dast_site_profile: dast_site_profile,
                dast_scanner_profile: dast_scanner_profile,
                branch_name: 'master',
                tags: tags
              )
            end

            let(:expected_yaml_configuration) do
              <<~YAML
                ---
                stages:
                - dast
                include:
                - template: #{template}
                dast:
                  dast_configuration:
                    site_profile: #{dast_site_profile.name}
                    scanner_profile: #{dast_scanner_profile.name}
                  tags:
                  - ruby
                  - postgres
              YAML
            end

            it_behaves_like 'a payload with a dast_profile'
          end
        end

        context 'when the scanner profile has no runner tags' do
          it_behaves_like 'a payload with a dast_profile'
        end
      end

      context 'when a dast_site_profile is provided' do
        shared_examples 'a payload without a dast_profile' do
          it 'returns a branch and YAML configuration' do
            expected_payload = {
              dast_profile: nil,
              branch: dast_profile.branch_name,
              ci_configuration: expected_yaml_configuration
            }

            expect(subject.payload).to eq(expected_payload)
          end
        end

        context 'when a dast_scanner_profile is provided' do
          let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile } }

          it_behaves_like 'a payload without a dast_profile'

          context 'when the target is not validated and an active scan is requested' do
            let_it_be(:active_dast_scanner_profile) { create(:dast_scanner_profile, project: project, scan_type: 'active') }

            let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: active_dast_scanner_profile } }

            it 'responds with an error message', :aggregate_failures do
              expect(subject).not_to be_success
              expect(subject.message).to eq('Cannot run active scan against unvalidated target')
            end
          end
        end

        context 'when a dast_scanner_profile is not provided' do
          let(:params) { { dast_site_profile: dast_site_profile } }

          let(:expected_yaml_configuration) do
            <<~YAML
              ---
              stages:
              - dast
              include:
              - template: #{template}
              dast:
                dast_configuration:
                  site_profile: #{dast_site_profile.name}
            YAML
          end

          it_behaves_like 'a payload without a dast_profile'
        end
      end

      context 'when a dast_site_profile is not provided' do
        let(:params) { { dast_site_profile: nil, dast_scanner_profile: dast_scanner_profile } }

        it 'responds with an error message', :aggregate_failures do
          expect(subject).not_to be_success
          expect(subject.message).to eq('Dast site profile was not provided')
        end
      end

      context 'when a branch is provided' do
        let(:params) { { dast_site_profile: dast_site_profile, dast_scanner_profile: dast_scanner_profile, branch: 'hello-world' } }

        it 'returns the branch in the payload' do
          expect(subject.payload[:branch]).to match('hello-world')
        end
      end
    end

    context 'when the target_type is NOT api' do
      let(:template) { on_demand_scan_template }

      it_behaves_like 'build service execute tests'
    end

    context 'when the target_type is api' do
      before do
        dast_site_profile.target_type = 'api'
      end

      let(:template) { api_scan_template }

      it_behaves_like 'build service execute tests'
    end
  end
end
