# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiCachedMessageType'], feature_category: :shared do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('AiCachedMessageType') }

  it 'has the expected fields' do
    expected_fields = %w[id request_id content role timestamp errors]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
