# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionAnalytics::DataFormatter, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:issue) { create(:closed_issue, project: project1) }
  let_it_be(:mr) { create(:merge_request, source_project: project2) }

  let(:data) do
    Gitlab::ContributionAnalytics::DataCollector.new(group: group).send(:events)
  end

  before_all do
    create(:event, :closed, project: project1, target: issue, author: user_1)
    create(:event, :created, project: project2, target: mr, author: user_1)
    create(:event, :approved, project: project2, target: mr, author: user_1)
    create(:event, :closed, project: project2, target: mr, author: user_1)
    create(:event, :pushed, project: project1, target: nil, author: user_1)
    create(:event, :pushed, project: project1, target: nil, author: user_2)
  end

  shared_examples 'correct collection of data' do
    describe '#totals' do
      it 'returns formatted data for received events' do
        data_formatter = described_class.new(data)

        expect(data_formatter.totals).to eq({
          issues_closed: { user_1.id => 1 },
          issues_created: {},
          merge_requests_created: { user_1.id => 1 },
          merge_requests_merged: {},
          merge_requests_approved: { user_1.id => 1 },
          merge_requests_closed: { user_1.id => 1 },
          push: { user_1.id => 1, user_2.id => 1 },
          total_events: { user_1.id => 5, user_2.id => 1 }
        })
      end

      describe '#users' do
        it 'returns correct users' do
          users = described_class.new(data).users

          expect(users).to match_array([user_1, user_2])
        end
      end
    end
  end

  context 'when postgres is the data source' do
    it_behaves_like 'correct collection of data'
  end

  context 'when clickhouse is the data source', :click_house do
    before do
      stub_feature_flags(clickhouse_data_collection: true)
    end

    it_behaves_like 'correct collection of data'
  end
end
