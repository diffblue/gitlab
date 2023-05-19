# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountWorkspacesMetric, feature_category: :remote_development do
  let_it_be(:workspace) { create(:workspace) }

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 1 }
    let(:expected_query) do
      %{SELECT COUNT("workspaces"."id") FROM "workspaces"}
    end
  end
end
