# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Loader do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:project) { create(:project, group: group) }

  subject(:serialized_data) do
    described_class.new(
      insights_entity: group,
      current_user: user,
      params: params
    ).execute
  end

  context 'when issuable data source is requested' do
    let_it_be(:label) { create(:group_label, title: 'bug', group: group) }
    let_it_be(:issue1) { create(:labeled_issue, labels: [label], project: project) }
    let_it_be(:issue2) { create(:labeled_issue, labels: [label], project: project) }

    let(:data_source_params) do
      {
        issuable_type: 'issues',
        collection_labels: ['bug'],
        group_by: 'day'
      }
    end

    let(:params) do
      {
        type: 'bar',
        query: {
          data_source: 'issuables',
          params: data_source_params
        }
      }
    end

    context 'when loading data for an issuable chart' do
      it 'returns the serialized data' do
        expect(serialized_data['datasets'].first['data'].sum).to eq(2)
      end

      context 'when the legacy format query params are given' do
        let(:params) do
          {
            type: 'bar',
            query: data_source_params
          }
        end

        it 'returns the serialized data' do
          expect(serialized_data['datasets'].first['data'].sum).to eq(2)
        end
      end
    end

    context 'when requesting a different data source' do
      before do
        params[:query][:data_source] = 'unknown'
      end

      it 'raises error' do
        expect { serialized_data }.to raise_error Gitlab::Insights::Validators::ParamsValidator::InvalidQueryError
      end
    end
  end

  context 'when dora data source is requested' do
    let(:environment) { create(:environment, :production, project: project) }
    let(:data_source_params) do
      {
        metric: 'time_to_restore_service',
        group_by: 'day',
        period_limit: 3
      }
    end

    let(:params) do
      {
        type: 'bar',
        query: {
          data_source: 'dora',
          params: data_source_params
        }
      }
    end

    before do
      stub_licensed_features(dora4_analytics: true)

      create(:dora_daily_metrics,
             time_to_restore_service_in_seconds: 2.days.seconds.to_i,
             environment: environment,
             date: Date.today)
    end

    it 'returns the serialized data' do
      expect(serialized_data['datasets'].first['data']).to eq([nil, nil, 2])
    end
  end
end
