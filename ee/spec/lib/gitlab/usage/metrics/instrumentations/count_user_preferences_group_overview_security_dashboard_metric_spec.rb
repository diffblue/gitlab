# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUserPreferencesGroupOverviewSecurityDashboardMetric, feature_category: :service_ping do
  context 'with time_frame: all' do
    let(:expected_value) { 3 }

    let_it_be(:user) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }
    let_it_be(:user2) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }
    let_it_be(:user3) { create(:user, group_view: :security_dashboard, created_at: 10.days.ago) }

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }
  end

  context 'with monthly aggregation' do
    let(:expected_value) { 2 }

    let_it_be(:user) { create(:user, group_view: :security_dashboard, created_at: 3.days.ago) }
    let_it_be(:user2) { create(:user, group_view: :security_dashboard, created_at: 10.days.ago) }
    let_it_be(:user3) { create(:user, group_view: :security_dashboard, created_at: 40.days.ago) }

    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }
  end
end
