# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Dora::PerformanceScoreCountType, feature_category: :dora_metrics do
  describe 'fields' do
    subject(:fields) { described_class.fields }

    it 'has proper types' do
      expect(fields['metricName']).to have_non_null_graphql_type(GraphQL::Types::String)
      expect(fields['lowProjectsCount']).to have_nullable_graphql_type(GraphQL::Types::Int)
      expect(fields['mediumProjectsCount']).to have_nullable_graphql_type(GraphQL::Types::Int)
      expect(fields['highProjectsCount']).to have_nullable_graphql_type(GraphQL::Types::Int)
      expect(fields['noDataProjectsCount']).to have_nullable_graphql_type(GraphQL::Types::Int)
    end
  end
end
