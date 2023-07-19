# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::AnalyticsDashboardsHelper, feature_category: :product_analytics do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project, group: group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:pointer) { create(:analytics_dashboards_pointer, :project_based, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:group_pointer) { create(:analytics_dashboards_pointer, namespace: group, target_project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  let(:product_analytics_instrumentation_key) { '1234567890' }

  before do
    allow(helper).to receive(:current_user) { user }
    allow(helper).to receive(:image_path).and_return('illustrations/chart-empty-state.svg')
    allow(helper).to receive(:project_analytics_dashboards_path).with(project).and_return('/-/analytics/dashboards')

    stub_application_setting(product_analytics_data_collector_host: 'https://new-collector.example.com')
    stub_application_setting(product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000')
    stub_application_setting(cube_api_base_url: 'https://cube.example.com')
    stub_application_setting(cube_api_key: '0987654321')
  end

  describe '#analytics_dashboards_list_app_data' do
    context 'for project' do
      where(
        :product_analytics_enabled_setting,
        :feature_flag_enabled,
        :licensed_feature_enabled,
        :user_has_permission,
        :enabled
      ) do
        true  | true | true | true | true
        false | true | true | true | false
        true  | false | true | true | false
        true  | true | false | true | false
        true  | true | true | false | false
      end

      with_them do
        before do
          project.project_setting.update!(product_analytics_instrumentation_key: product_analytics_instrumentation_key)

          stub_application_setting(product_analytics_enabled: product_analytics_enabled_setting)

          stub_feature_flags(product_analytics_dashboards: feature_flag_enabled,
            product_analytics_snowplow_support: false)
          stub_licensed_features(product_analytics: licensed_feature_enabled)

          allow(helper).to receive(:can?).with(user, :read_product_analytics, project).and_return(user_has_permission)
        end

        subject(:data) { helper.analytics_dashboards_list_app_data(project) }

        def expected_data(snowplow_enabled)
          {
            is_project: 'true',
            namespace_id: project.id,
            dashboard_project: {
              id: pointer.target_project.id,
              full_path: pointer.target_project.full_path,
              name: pointer.target_project.name
            }.to_json,
            tracking_key: user_has_permission ? product_analytics_instrumentation_key : nil,
            collector_host: user_has_permission ? 'https://new-collector.example.com' : nil,
            chart_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
            dashboard_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
            namespace_full_path: project.full_path,
            features: (enabled && snowplow_enabled ? [:product_analytics] : []).to_json,
            router_base: '/-/analytics/dashboards'
          }
        end

        context 'without snowplow' do
          before do
            stub_feature_flags(product_analytics_snowplow_support: false)
          end

          it 'returns the expected data' do
            expect(data).to eq(expected_data(false))
          end
        end

        context 'with snowplow' do
          before do
            stub_application_setting(product_analytics_configurator_connection_string: 'http://localhost:3000')
          end

          it 'returns the expected data' do
            expect(data).to eq(expected_data(true))
          end
        end
      end
    end

    context 'for group' do
      subject(:data) { helper.analytics_dashboards_list_app_data(group) }

      def expected_data(collector_host)
        {
          is_project: 'false',
          namespace_id: group.id,
          dashboard_project: {
            id: group_pointer.target_project.id,
            full_path: group_pointer.target_project.full_path,
            name: group_pointer.target_project.name
          }.to_json,
          tracking_key: nil,
          collector_host: collector_host ? 'https://new-collector.example.com' : nil,
          chart_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
          dashboard_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
          namespace_full_path: group.full_path,
          features: [].to_json,
          router_base: "/groups/#{group.full_path}/-/analytics/dashboards"
        }
      end

      context 'when user does not have permission' do
        before do
          allow(helper).to receive(:can?).with(user, :read_product_analytics, group).and_return(false)
        end

        it 'returns the expected data' do
          expect(data).to eq(expected_data(false))
        end
      end

      context 'when user has permission' do
        before do
          allow(helper).to receive(:can?).with(user, :read_product_analytics, group).and_return(true)
        end

        it 'returns the expected data' do
          expect(data).to eq(expected_data(true))
        end
      end
    end

    describe 'tracking_key' do
      where(
        :can_read_product_analytics,
        :project_instrumentation_key,
        :expected
      ) do
        false | nil | nil
        true | 'snowplow-key' | 'snowplow-key'
        true | nil | nil
      end

      with_them do
        before do
          project.project_setting.update!(product_analytics_instrumentation_key: project_instrumentation_key)

          stub_application_setting(product_analytics_configurator_connection_string: 'https://configurator.example.com')
          stub_application_setting(product_analytics_enabled: can_read_product_analytics)
          stub_feature_flags(product_analytics_dashboards: can_read_product_analytics)
          stub_licensed_features(product_analytics: can_read_product_analytics)
          allow(helper).to receive(:can?).with(user, :read_product_analytics,
            project).and_return(can_read_product_analytics)
        end

        subject(:data) { helper.analytics_dashboards_list_app_data(project) }

        it 'returns the expected tracking_key' do
          expect(data[:tracking_key]).to eq(expected)
        end
      end
    end
  end

  describe '#analytics_project_settings_data' do
    where(
      :can_read_product_analytics,
      :project_instrumentation_key,
      :expected_tracking_key
    ) do
      false | nil | nil
      true | 'snowplow-key' | 'snowplow-key'
      true | nil | nil
    end

    with_them do
      before do
        project.project_setting.update!(product_analytics_instrumentation_key: project_instrumentation_key)

        stub_application_setting(product_analytics_enabled: can_read_product_analytics)

        stub_feature_flags(product_analytics_dashboards: can_read_product_analytics)
        stub_licensed_features(product_analytics: can_read_product_analytics)

        allow(helper).to receive(:can?).with(user, :read_product_analytics,
          project).and_return(can_read_product_analytics)
      end

      subject(:data) { helper.analytics_project_settings_data(project) }

      it 'returns the expected data' do
        expect(data).to eq({
          tracking_key: can_read_product_analytics ? expected_tracking_key : nil,
          collector_host: can_read_product_analytics ? 'https://new-collector.example.com' : nil,
          dashboards_path: '/-/analytics/dashboards'
        })
      end
    end
  end
end
