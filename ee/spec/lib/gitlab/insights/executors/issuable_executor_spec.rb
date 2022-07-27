# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Executors::IssuableExecutor do
  let_it_be(:group) { create(:group) }
  let_it_be(:label) { create(:group_label, group: group) }
  let_it_be(:user) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, labels: [label], project: project, created_at: 2.days.ago) }

  let(:chart_type) { 'bar' }

  let(:query_params) do
    {
      issuable_type: 'issue',
      group_by: 'day',
      period_limit: 5
    }
  end

  subject(:serialized_data) do
    described_class.new(
      query_params: query_params,
      current_user: user,
      insights_entity: insights_entity,
      projects: [],
      chart_type: chart_type
    ).execute
  end

  shared_examples 'IssuableExecutor examples' do
    it 'returns serialized data' do
      date = issue.created_at.strftime('%d %b %y')
      index = serialized_data['labels'].index(date)

      serie = serialized_data['datasets'].first
      expect(serie['data'][index]).to eq(1)
    end
  end

  context 'when requesting data for group' do
    let(:insights_entity) { group }

    it_behaves_like 'IssuableExecutor examples'

    context 'when line type is given' do
      let(:chart_type) { 'line' }

      before do
        query_params[:collection_labels] = [label.title]
      end

      it_behaves_like 'IssuableExecutor examples'
    end
  end

  context 'when requesting data for project' do
    let(:insights_entity) { project }

    it_behaves_like 'IssuableExecutor examples'
  end
end
