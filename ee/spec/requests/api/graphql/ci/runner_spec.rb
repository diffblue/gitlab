# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.runner(id)', feature_category: :runner_fleet do
  include GraphqlHelpers
  include RunnerReleasesHelper

  let_it_be(:admin) { create(:user, :admin) }

  shared_examples 'runner details fetch operation returning expected upgradeStatus' do
    let(:query) do
      managers_path = query_graphql_path(%i[managers nodes], 'id upgradeStatus')

      wrap_fields(query_graphql_path(query_path, "id upgradeStatus #{managers_path}"))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: current_user)

      runner_data = graphql_data_at(:runner)

      expect(runner_data).not_to be_nil
      expect(runner_data).to match a_graphql_entity_for(runner, upgrade_status: expected_upgrade_status)
      expect(graphql_dig_at(runner_data, :managers, :nodes)).to match [
        a_graphql_entity_for(runner_manager1, upgrade_status: expected_manager1_upgrade_status),
        a_graphql_entity_for(runner_manager2, upgrade_status: expected_manager2_upgrade_status)
      ]
    end

    context 'when fetching runner releases is disabled' do
      before do
        stub_application_setting(update_runner_versions_enabled: false)
      end

      it 'retrieves runner data with nil upgrade status' do
        post_graphql(query, current_user: current_user)

        runner_data = graphql_data_at(:runner)

        expect(runner_data).not_to be_nil
        expect(runner_data).to match a_graphql_entity_for(runner, upgrade_status: nil)
      end
    end
  end

  describe 'upgradeStatus', :saas do
    let_it_be(:runner) { create(:ci_runner, description: 'Runner 1', version: '14.1.0', revision: 'b') }

    context 'with runner with 2 runner managers' do
      let_it_be(:runner_manager2) do
        create(:ci_runner_machine, runner: runner, version: '14.0.0', revision: 'a')
      end

      let_it_be(:runner_manager1) do
        create(:ci_runner_machine, runner: runner, version: '14.1.0', revision: 'b')
      end

      let!(:manager1_version) do
        create(:ci_runner_version, version: runner_manager1.version, status: db_version_status(manager1_version_status))
      end

      let!(:manager2_version) do
        create(:ci_runner_version, version: runner_manager2.version, status: db_version_status(manager2_version_status))
      end

      let(:manager1_version_status) { nil }
      let(:manager2_version_status) { nil }

      def db_version_status(status)
        status == :error ? nil : status
      end

      context 'with mocked RunnerUpgradeCheck' do
        using RSpec::Parameterized::TableSyntax

        before do
          # Set up stubs for runner manager status checks
          allow_next_instance_of(::Gitlab::Ci::RunnerUpgradeCheck) do |instance|
            allow(instance).to receive(:check_runner_upgrade_suggestion)
              .with(runner_manager1.version)
              .and_return([nil, manager1_version_status])
              .once
            allow(instance).to receive(:check_runner_upgrade_suggestion)
              .with(runner_manager2.version)
              .and_return([nil, manager2_version_status])
              .once
          end
        end

        shared_examples 'when runner managers have all possible statuses' do
          where(:manager1_version_status, :manager2_version_status,
                :expected_manager1_upgrade_status,
                :expected_manager2_upgrade_status, :expected_upgrade_status) do
            :error           | :error           | nil             | nil             | nil
            :invalid_version | :invalid_version | 'INVALID'       | 'INVALID'       | 'INVALID'
            :unavailable     | :unavailable     | 'NOT_AVAILABLE' | 'NOT_AVAILABLE' | 'NOT_AVAILABLE'
            :unavailable     | :available       | 'NOT_AVAILABLE' | 'AVAILABLE'     | 'AVAILABLE'
            :unavailable     | :recommended     | 'NOT_AVAILABLE' | 'RECOMMENDED'   | 'RECOMMENDED'
            :available       | :unavailable     | 'AVAILABLE'     | 'NOT_AVAILABLE' | 'AVAILABLE'
            :available       | :available       | 'AVAILABLE'     | 'AVAILABLE'     | 'AVAILABLE'
            :available       | :recommended     | 'AVAILABLE'     | 'RECOMMENDED'   | 'RECOMMENDED'
            :recommended     | :recommended     | 'RECOMMENDED'   | 'RECOMMENDED'   | 'RECOMMENDED'
          end

          with_them do
            it_behaves_like 'runner details fetch operation returning expected upgradeStatus'
          end
        end

        context 'requested by non-paid user' do
          let(:current_user) { admin }

          context 'with RunnerUpgradeCheck returning :available' do
            let(:manager1_version_status) { :available }
            let(:manager2_version_status) { :available }
            let(:expected_manager1_upgrade_status) { nil }
            let(:expected_manager2_upgrade_status) { nil }
            let(:expected_upgrade_status) { nil } # non-paying users always see nil

            it_behaves_like 'runner details fetch operation returning expected upgradeStatus'
          end
        end

        context 'requested on an instance with runner_upgrade_management' do
          let(:current_user) { admin }

          before do
            stub_licensed_features(runner_upgrade_management: true)
          end

          it_behaves_like 'when runner managers have all possible statuses'

          context 'with multiple runners' do
            let(:admin2) { create(:admin) }
            let(:query) do
              managers_path = query_graphql_path(%i[managers nodes], 'upgradeStatus')

              wrap_fields(query_graphql_path(%i[runners nodes], "id upgradeStatus #{managers_path}"))
            end

            it 'does not generate N+1 queries', :request_store, :use_sql_query_cache do
              # warm-up cache and so on:
              personal_access_token = create(:personal_access_token, user: admin)
              personal_access_token2 = create(:personal_access_token, user: admin)
              args = { current_user: admin, token: { personal_access_token: personal_access_token } }
              args2 = { current_user: admin2, token: { personal_access_token: personal_access_token2 } }

              control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
                post_graphql(query, **args)
              end

              create(:ci_runner, version: runner_manager1.version)

              expect { post_graphql(query, **args2) }.not_to exceed_all_query_limit(control)
            end
          end
        end

        context 'requested by paid user' do
          let_it_be(:user) { create(:user, :admin, namespace: create(:user_namespace)) }
          let_it_be(:ultimate_group) do
            create(:group_with_plan, plan: :ultimate_plan).tap { |g| g.add_reporter(user) }
          end

          let(:current_user) { user }

          it_behaves_like 'when runner managers have all possible statuses'
        end
      end

      context 'integration test with Gitlab::Ci::RunnerUpgradeCheck' do
        before do
          stub_licensed_features(runner_upgrade_management: true)
          stub_runner_releases(%w[14.0.0 14.1.0])
        end

        let(:current_user) { admin }

        let(:query) do
          managers_path = query_graphql_path(%i[managers nodes], 'id upgradeStatus')

          wrap_fields(query_graphql_path(query_path, "id upgradeStatus #{managers_path}"))
        end

        let(:query_path) do
          [
            [:runner, { id: runner.to_global_id.to_s }]
          ]
        end

        it 'retrieves expected fields' do
          post_graphql(query, current_user: current_user)

          runner_data = graphql_data_at(:runner)
          expect(graphql_dig_at(runner_data, :managers, :nodes)).to match [
            a_graphql_entity_for(runner_manager1, upgrade_status: 'NOT_AVAILABLE'),
            a_graphql_entity_for(runner_manager2, upgrade_status: 'AVAILABLE')
          ]
        end
      end
    end
  end

  describe 'jobsStatistics', :freeze_time do
    let_it_be(:project) { create(:project) }
    let_it_be(:project_runner1) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:project_runner2) { create(:ci_runner, :project, projects: [project]) }
    let_it_be(:pipeline1) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline2) { create(:ci_pipeline, project: project) }

    let(:query) do
      %(
        query {
          runners(type: PROJECT_TYPE) {
            jobsStatistics { #{all_graphql_fields_for('CiJobsStatistics')} }
          }
        }
      )
    end

    subject(:jobs_data) do
      post_graphql(query, current_user: current_user)

      graphql_data_at(:runners, :jobs_statistics)
    end

    context 'requested by an administrator' do
      let(:current_user) { admin }

      context 'when licensed' do
        before do
          stub_licensed_features(runner_performance_insights: true)
        end

        context 'with builds' do
          let!(:build1) do
            create(:ci_build, :running, runner: project_runner1, pipeline: pipeline1,
                   queued_at: 5.minutes.ago, started_at: 1.minute.ago)
          end

          let!(:build2) do
            create(:ci_build, :success, runner: project_runner2, pipeline: pipeline2,
                   queued_at: 10.minutes.ago, started_at: 8.minutes.ago, finished_at: 7.minutes.ago)
          end

          it 'retrieves expected fields' do
            expect(jobs_data).not_to be_nil
            expect(jobs_data).to match a_hash_including(
              'queuedDuration' => {
                'p50' => 180.0,
                'p75' => 210.0,
                'p90' => 228.0,
                'p95' => 234.0,
                'p99' => 238.8
              }
            )
          end
        end

        context 'with no builds' do
          it 'retrieves expected fields with nil values' do
            expect(jobs_data).not_to be_nil
            expect(jobs_data).to match a_hash_including(
              'queuedDuration' => {
                'p50' => nil,
                'p75' => nil,
                'p90' => nil,
                'p95' => nil,
                'p99' => nil
              }
            )
          end
        end
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(runner_performance_insights: false)
        end

        context 'with builds' do
          let!(:build1) do
            create(:ci_build, :running, runner: project_runner1, pipeline: pipeline1,
                   queued_at: 5.minutes.ago, started_at: 1.minute.ago)
          end

          specify { expect(jobs_data).to be_nil }
        end
      end
    end
  end
end
