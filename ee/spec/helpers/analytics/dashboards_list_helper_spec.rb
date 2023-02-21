# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DashboardsListHelper, feature_category: :product_analytics do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) } # rubocop:disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:user) { build_stubbed(:user) }

  let(:dashboards_path) { '/mock/project' }
  let(:jitsu_key) { '1234567890' }
  let(:jitsu_host) { 'https://jitsu.example.com' }
  let(:jitsu_project_xid) { '123' }

  before do
    allow(helper).to receive(:current_user) { user }
    allow(helper).to receive(:project_analytics_dashboards_path).with(project).and_return(dashboards_path)
    allow(helper).to receive(:image_path).and_return('illustrations/chart-empty-state.svg')

    stub_application_setting(jitsu_host: jitsu_host)
    stub_application_setting(jitsu_project_xid: jitsu_project_xid)
    stub_application_setting(jitsu_administrator_email: 'test@example.com')
    stub_application_setting(jitsu_administrator_password: 'password')
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

        stub_feature_flags(product_analytics_internal_preview: feature_flag_enabled)
        stub_licensed_features(product_analytics: licensed_feature_enabled)

        allow(helper).to receive(:can?).with(user, :read_product_analytics, project).and_return(user_has_permission)
      end

      subject(:data) { helper.analytics_dashboards_list_app_data(project) }

      it 'returns the expected data' do
        expect(helper.analytics_dashboards_list_app_data(project)).to eq({
          project_id: project.id,
          jitsu_key: jitsu_key,
          jitsu_host: jitsu_host,
          jitsu_project_id: jitsu_project_xid,
          chart_empty_state_illustration_path: 'illustrations/chart-empty-state.svg',
          project_full_path: project.full_path,
          router_base: dashboards_path,
          features: {
            product_analytics: enabled
          }.to_json
        })
      end
    end
  end
end
