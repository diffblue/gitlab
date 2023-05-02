# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::VulnerabilitiesCountPerDayResolver, feature_category: :vulnerability_management do
  include GraphqlHelpers

  subject(:ordered_history) { resolve(described_class, obj: group, args: args, ctx: { current_user: current_user }) }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:project_2) { create(:project, namespace: group) }
  let_it_be(:current_user) { create(:user) }

  describe '#resolve' do
    let(:start_date) { Date.new(2019, 10, 15) }
    let(:end_date) { Date.new(2019, 10, 21) }
    let(:args) { { start_date: start_date, end_date: end_date } }

    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'when the current user has access' do
      before do
        group.add_maintainer(current_user)
      end

      it 'fetches historical vulnerability data from the start date to the end date' do
        travel_to(Date.new(2019, 10, 31)) do
          create(:vulnerability_historical_statistic, date: start_date + 1.day, total: 2, critical: 1, high: 1, project: project)
          create(:vulnerability_historical_statistic, date: start_date + 2.days, total: 3, critical: 2, high: 1, project: project)
          create(:vulnerability_historical_statistic, date: start_date + 4.days, total: 1, critical: 1, high: 0, project: project_2)

          expected_history = [
            { 'total' => 0, 'critical' => 0, 'high' => 0, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date },
            { 'total' => 2, 'critical' => 1, 'high' => 1, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date + 1.day },
            { 'total' => 3, 'critical' => 2, 'high' => 1, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date + 2.days },
            { 'total' => 3, 'critical' => 2, 'high' => 1, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date + 3.days },
            { 'total' => 1, 'critical' => 1, 'high' => 0, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date + 4.days },
            { 'total' => 1, 'critical' => 1, 'high' => 0, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => start_date + 5.days },
            { 'total' => 1, 'critical' => 1, 'high' => 0, 'medium' => 0, 'low' => 0, 'unknown' => 0, 'info' => 0, 'date' => end_date }
          ].as_json

          expect(ordered_history.as_json).to match_array(expected_history)
        end
      end
    end

    context 'when the current user does not have access' do
      it 'returns an empty response' do
        expect(ordered_history).to be_blank
      end
    end
  end
end
