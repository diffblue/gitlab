# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DashboardsPointer, type: :model, feature_category: :devops_reports do
  subject { build(:analytics_dashboards_pointer) }

  it { is_expected.to belong_to(:namespace).required }
  it { is_expected.to belong_to(:project).required }
  it { is_expected.to validate_uniqueness_of(:namespace_id) }
end
