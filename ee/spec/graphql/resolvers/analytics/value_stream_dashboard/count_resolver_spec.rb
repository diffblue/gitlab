# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Analytics::ValueStreamDashboard::CountResolver, feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:developer) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:count1) do
    create(:value_stream_dashboard_count, metric: :groups, count: 10, namespace: subgroup, recorded_at: '2023-05-20')
  end

  let_it_be(:count2) do
    create(:value_stream_dashboard_count, metric: :groups, count: 20, namespace: subgroup, recorded_at: '2023-04-20')
  end

  let(:arguments) { { identifier: 'groups', timeframe: { start: '2023-05-01', end: '2023-05-31' } } }
  let(:current_user) { developer }

  describe '#resolve' do
    subject(:result) { resolve(described_class, obj: group, args: arguments, ctx: { current_user: current_user }) }

    context 'when the feature is available' do
      before do
        stub_licensed_features(group_level_analytics_dashboard: true)
      end

      it 'returns the correct count' do
        expect(result[:count]).to eq(10)
      end

      context 'when querying an empty date range' do
        before do
          arguments[:timeframe][:start] = '2023-01-01'
          arguments[:timeframe][:end] = '2023-01-31'
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end

      context 'when the user is not authorized' do
        let(:current_user) { other_user }

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end
    end

    context 'when the feature is not available' do
      it 'returns the correct count' do
        expect(result).to eq(nil)
      end
    end
  end
end
