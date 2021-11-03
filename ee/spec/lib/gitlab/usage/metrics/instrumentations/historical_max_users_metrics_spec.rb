# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::HistoricalMaxUsersMetric do
  it_behaves_like 'a correct instrumented metric value', { time_frame: 'none', data_source: 'ruby' } do
    let(:expected_value) { ::License.current.historical_max }
  end
end
