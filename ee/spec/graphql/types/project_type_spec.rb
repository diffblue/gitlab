# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Project'] do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project, severity: :high) }

  before do
    stub_licensed_features(security_dashboard: true)

    project.add_developer(user)
  end

  it 'includes the ee specific fields' do
    expected_fields = %w[
      security_training_providers vulnerabilities vulnerability_scanners requirement_states_count
      vulnerability_severities_count packages compliance_frameworks vulnerabilities_count_by_day
      security_dashboard_path iterations iteration_cadences repository_size_excess actual_repository_size_limit
      code_coverage_summary api_fuzzing_ci_configuration corpuses path_locks incident_management_escalation_policies
      incident_management_escalation_policy scan_execution_policies network_policies security_training_urls
      vulnerability_images only_allow_merge_if_all_status_checks_passed dependencies merge_requests_disable_committers_approval
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'product analytics' do
    describe 'tracking_key' do
      where(
        :can_read_product_analytics,
        :snowplow_feature_flag_enabled,
        :project_jitsu_key,
        :project_instrumentation_key,
        :expected
      ) do
        false | false | nil | nil | nil
        false | true | nil | nil | nil
        true | false | 'jitsu-key' | 'snowplow-key' | 'jitsu-key'
        true | true | 'jitsu-key' | 'snowplow-key' | 'snowplow-key'
        true | true | 'jitsu-key' | nil | 'jitsu-key'
        true | true | nil | 'snowplow-key' | 'snowplow-key'
      end

      with_them do
        let_it_be(:project) { create(:project) }

        before do
          project.project_setting.update!(jitsu_key: project_jitsu_key)
          project.project_setting.update!(product_analytics_instrumentation_key: project_instrumentation_key)

          stub_application_setting(product_analytics_enabled: can_read_product_analytics)
          stub_feature_flags(product_analytics_dashboards: can_read_product_analytics, product_analytics_snowplow_support: snowplow_feature_flag_enabled)
          stub_licensed_features(product_analytics: can_read_product_analytics)
        end

        let(:query) do
          %(
            query {
              project(fullPath: "#{project.full_path}") {
                trackingKey
              }
            }
          )
        end

        subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

        it 'returns the expected tracking_key' do
          tracking_key = subject.dig('data', 'project', 'trackingKey')
          expect(tracking_key).to eq(expected)
        end
      end
    end
  end

  describe 'security_scanners' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch) }
    let_it_be(:user) { create(:user) }

    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            securityScanners {
              enabled
              available
              pipelineRun
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      create(:ci_build, :success, :sast, pipeline: pipeline)
      create(:ci_build, :success, :dast, pipeline: pipeline)
      create(:ci_build, :success, :license_scanning, pipeline: pipeline)
      create(:ci_build, :pending, :secret_detection, pipeline: pipeline)
    end

    it 'returns a list of analyzers enabled for the project' do
      query_result = subject.dig('data', 'project', 'securityScanners', 'enabled')
      expect(query_result).to match_array(%w[SAST DAST SECRET_DETECTION])
    end

    it 'returns a list of analyzers which were run in the last pipeline for the project' do
      query_result = subject.dig('data', 'project', 'securityScanners', 'pipelineRun')
      expect(query_result).to match_array(%w[DAST SAST])
    end
  end

  describe 'vulnerabilities' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:vulnerability) do
      create(:vulnerability, :detected, :critical, :with_finding, project: project, title: 'A terrible one!')
    end

    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            vulnerabilities {
              nodes {
                title
                severity
                state
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    it "returns the project's vulnerabilities" do
      vulnerabilities = subject.dig('data', 'project', 'vulnerabilities', 'nodes')

      expect(vulnerabilities.count).to be(1)
      expect(vulnerabilities.first['title']).to eq('A terrible one!')
      expect(vulnerabilities.first['state']).to eq('DETECTED')
      expect(vulnerabilities.first['severity']).to eq('CRITICAL')
    end
  end

  describe 'code coverage summary field' do
    subject { described_class.fields['codeCoverageSummary'] }

    it { is_expected.to have_graphql_type(Types::Ci::CodeCoverageSummaryType) }
  end

  describe 'compliance_frameworks' do
    it 'queries in batches', :request_store, :use_clean_rails_memory_store_caching do
      projects = create_list(:project, 2, :with_compliance_framework)

      projects.each do |p|
        p.add_maintainer(user)
        # Cache warm up: runs authorization for each user.
        resolve_field(:id, p, current_user: user)
      end

      results = batch_sync(max_queries: 1) do
        projects.flat_map do |p|
          resolve_field(:compliance_frameworks, p, current_user: user)
        end
      end
      frameworks = results.flat_map(&:to_a)

      expect(frameworks).to match_array(projects.flat_map(&:compliance_management_framework))
    end
  end

  describe 'push rules field' do
    subject { described_class.fields['pushRules'] }

    it { is_expected.to have_graphql_type(Types::PushRulesType) }
  end

  shared_context 'is an orchestration policy' do
    let(:security_policy_management_project) { create(:project) }
    let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project, security_policy_management_project: security_policy_management_project) }
    let(:policy_yaml) { Gitlab::Config::Loader::Yaml.new(fixture_file('security_orchestration.yml', dir: 'ee')).load! }

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      allow_next_found_instance_of(Security::OrchestrationPolicyConfiguration) do |policy|
        allow(policy).to receive(:policy_configuration_valid?).and_return(true)
        allow(policy).to receive(:policy_hash).and_return(policy_yaml)
        allow(policy).to receive(:policy_last_updated_at).and_return(Time.now)
      end

      stub_licensed_features(security_orchestration_policies: true)
      policy_configuration.security_policy_management_project.add_maintainer(user)
    end
  end

  describe 'scan_execution_policies' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            scanExecutionPolicies {
              nodes {
                name
                description
                enabled
                yaml
                updatedAt
              }
            }
          }
        }
      )
    end

    include_context 'is an orchestration policy'

    it 'returns associated scan execution policies' do
      policies = subject.dig('data', 'project', 'scanExecutionPolicies', 'nodes')

      expect(policies.count).to be(8)
    end
  end

  describe 'scan_result_policies' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            scanResultPolicies {
              nodes {
                name
                description
                enabled
                yaml
                updatedAt
              }
            }
          }
        }
      )
    end

    include_context 'is an orchestration policy'

    it 'returns associated scan result policies' do
      policies = subject.dig('data', 'project', 'scanResultPolicies', 'nodes')

      expect(policies.count).to be(8)
    end
  end

  describe 'dora field' do
    subject { described_class.fields['dora'] }

    it { is_expected.to have_graphql_type(Types::DoraType) }
  end

  describe 'vulnerability_images' do
    let_it_be(:vulnerability) { create(:vulnerability, project: project, report_type: :cluster_image_scanning) }
    let_it_be(:finding) do
      create(:vulnerabilities_finding, :with_cluster_image_scanning_scanning_metadata,
             project: project, vulnerability: vulnerability)
    end

    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            vulnerabilityImages {
              nodes {
                name
              }
            }
          }
        }
      )
    end

    subject(:vulnerability_images) do
      result = GitlabSchema.execute(query, context: { current_user: current_user }).as_json
      result.dig('data', 'project', 'vulnerabilityImages', 'nodes', 0)
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.to be_nil }
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      it 'returns a list of container images reported for vulnerabilities' do
        expect(vulnerability_images).to eq('name' => 'alpine:3.7')
      end
    end
  end

  private

  def query_for_project(project)
    graphql_query_for(
      :projects, { ids: [global_id_of(project)] }, "nodes { #{query_nodes(:compliance_frameworks)} }"
    )
  end
end
