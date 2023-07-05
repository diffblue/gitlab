# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionAnalytics::PostgresqlDataCollector, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  it 'returns correct data' do
    # before the date range
    create(:event, :pushed, project: project1, target: nil, created_at: 4.months.ago, author: user1)
    # after the date range
    create(:event, :pushed, project: project1, target: nil, created_at: Date.today, author: user2)
    # in the range range
    create(:event, :pushed, project: project2, target: nil, created_at: 2.months.ago, author: user1)
    create(:event, :pushed, project: project2, target: nil, created_at: 2.months.ago, author: user1)
    create(:event, :merged, project: project1, target: nil, created_at: 1.month.ago, author: user1,
      target_type: ::MergeRequest.name)
    create(:event, :created, project: project2, target: nil, created_at: 2.weeks.ago, author: user2,
      target_type: ::MergeRequest.name)

    data =
      described_class.new(group: group, from: 3.months.ago, to: 1.week.ago)
        .totals_by_author_target_type_action

    expect(data).to be_an_instance_of(Hash)
    expect(data).to eq(
      {
        [user1.id, "MergeRequest", "merged"] => 1,
        [user1.id, nil, "pushed"] => 2,
        [user2.id, "MergeRequest", "created"] => 1
      }
    )
  end
end
