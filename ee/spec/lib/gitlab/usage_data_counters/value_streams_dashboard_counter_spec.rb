# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::ValueStreamsDashboardCounter, feature_category: :team_planning do
  it_behaves_like 'a redis usage counter', 'ValueStreamsDashboard', 'views'
  it_behaves_like 'a redis usage counter with totals', :value_streams_dashboard, views: 2
end
