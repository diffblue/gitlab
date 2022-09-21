# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::EpicsDeepestRelationshipLevelMetric do
  before_all do
    group = create(:group)
    create(:epic, group: group, parent: create(:epic, group: group))
  end
  let(:expected_value) { 2 }

  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
end
