# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::AnalyticsDashboardsHelper, feature_category: :product_analytics do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:pointer) { create(:analytics_dashboards_pointer, :project_based, project: project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

  let(:jitsu_key) { '1234567890' }

  before do
    allow(helper).to receive(:current_user) { user }
    allow(helper).to receive(:image_path).and_return('illustrations/chart-empty-state.svg')
    allow(helper).to receive(:project_analytics_dashboards_path).with(project).and_return('/-/analytics/dashboards')

    stub_application_setting(jitsu_host: 'https://jitsu.example.com')
    stub_application_setting(jitsu_project_xid: '123')
    stub_application_setting(jitsu_administrator_email: 'test@example.com')
    stub_application_setting(jitsu_administrator_password: 'password')
    stub_application_setting(product_analytics_data_collector_host: 'https://new-collector.example.com')
    stub_application_setting(product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000')
    stub_application_setting(cube_api_base_url: 'https://cube.example.com')
    stub_application_setting(cube_api_key: '0987654321')
  end

  describe '#analytics_dashboards_list_app_data' do
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
        project.project_setting.update!(jitsu_key: jitsu_key)

        stub_application_setting(product_analytics_enabled: product_analytics_enabled_setting)

        stub_feature_flags(product_analytics_dashboards: feature_flag_enabled)
        stub_licensed_features(product_analytics: licensed_feature_enabled)

        allow(helper).to receive(:can?).with(user, :read_product_analytics, project).and_return(user_has_permission)
      end

      subject(:data) { helper.analytics_dashboards_list_app_data(project) }

      it 'returns the expected data' do
        expect(data).to eq({
          project_id: project.id,
          dashboard_project: {
            id: pointer.target_project.id,
            full_path: pointer.target_project.full_path,
            name: pointer.target_project.name
          }.to_json,
          tracking_key: user_has_permission ? jitsu_key : nil,
          collector_host: user_has_permission ? 'https://new-collector.example.com' : nil,
          chart_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
          dashboard_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
          project_full_path: project.full_path,
          features: (enabled ? [:product_analytics] : []).to_json,
          router_base: '/-/analytics/dashboards'
        })
      end
    end

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
        before do
          project.project_setting.update!(jitsu_key: project_jitsu_key)
          project.project_setting.update!(product_analytics_instrumentation_key: project_instrumentation_key)

          stub_application_setting(product_analytics_enabled: can_read_product_analytics)
          stub_feature_flags(product_analytics_dashboards: can_read_product_analytics,
            product_analytics_snowplow_support: snowplow_feature_flag_enabled)
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
end
