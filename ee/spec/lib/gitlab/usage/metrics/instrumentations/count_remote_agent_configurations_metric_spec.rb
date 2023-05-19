# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountRemoteAgentConfigurationsMetric, feature_category: :remote_development do
  before do
    configs = create_list(:remote_development_agent_config, 2)
    create(:remote_development_agent_config, cluster_agent_id: configs[0].cluster_agent_id)
  end

  it_behaves_like 'a correct instrumented metric value and query', { time_frame: 'all', data_source: 'database' } do
    let(:expected_value) { 2 }
    let(:expected_query) do
      'SELECT COUNT(DISTINCT "remote_development_agent_configs"."cluster_agent_id") ' \
        'FROM "remote_development_agent_configs"'
    end
  end
end
