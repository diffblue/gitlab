# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::PerformanceScore, type: :model, feature_category: :value_stream_management do
  subject { build :dora_performance_score }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:project) }
  it { is_expected.to validate_presence_of(:date) }
  it { is_expected.to validate_uniqueness_of(:date).scoped_to(:project_id) }
end
