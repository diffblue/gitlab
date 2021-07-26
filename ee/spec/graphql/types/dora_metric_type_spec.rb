# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::DoraMetricType do
  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:date, :value)
  end

  describe 'date field' do
    subject { described_class.fields['date'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::String) }
  end

  describe 'value field' do
    subject { described_class.fields['value'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::Int) }
  end
end
