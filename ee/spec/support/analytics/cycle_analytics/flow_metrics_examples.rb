# frozen_string_literal: true

RSpec.shared_examples 'value stream analytics flow metrics leadTime examples' do
  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:label) { create(:group_label, group: group) }

  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }

  let_it_be(:issue1) do
    create(:issue, project: project1, author: author, created_at: 17.days.ago, closed_at: 12.days.ago)
  end

  let_it_be(:issue2) do
    create(:issue, project: project2, author: author, created_at: 16.days.ago, closed_at: 13.days.ago)
  end

  let_it_be(:issue3) do
    create(:labeled_issue,
      project: project1,
      labels: [label],
      author: author,
      milestone: milestone,
      assignees: [assignee],
      created_at: 14.days.ago,
      closed_at: 11.days.ago)
  end

  let_it_be(:issue4) do
    create(:labeled_issue,
      project: project2,
      labels: [label],
      assignees: [assignee],
      created_at: 20.days.ago,
      closed_at: 15.days.ago)
  end

  before do
    Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute
  end

  let(:query) do
    <<~QUERY
      query($path: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!], $from: Time!, $to: Time!) {
        #{context}(fullPath: $path) {
          flowMetrics {
            leadTime(assigneeUsernames: $assigneeUsernames, authorUsername: $authorUsername, milestoneTitle: $milestoneTitle, labelNames: $labelNames, from: $from, to: $to) {
              value
              unit
              identifier
              title
              links {
                label
                url
              }
            }
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      path: full_path,
      from: 21.days.ago.iso8601,
      to: 10.days.ago.iso8601
    }
  end

  subject(:result) do
    post_graphql(query, current_user: current_user, variables: variables)

    graphql_data.dig(context.to_s, 'flowMetrics', 'leadTime')
  end

  it 'returns the correct value' do
    expect(result).to match(a_hash_including({
      'identifier' => 'lead_time',
      'unit' => n_('day', 'days', 4),
      'value' => 4,
      'title' => _('Lead Time'),
      'links' => [
        { 'label' => s_('ValueStreamAnalytics|Dashboard'), 'url' => match(/issues_analytics/) },
        { 'label' => s_('ValueStreamAnalytics|Go to docs'), 'url' => match(/definitions/) }
      ]
    }))
  end

  context 'when the user is not authorized' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      expect(result).to eq(nil)
    end
  end

  context 'when outside of the date range' do
    let(:variables) do
      {
        path: full_path,
        from: 30.days.ago.iso8601,
        to: 25.days.ago.iso8601
      }
    end

    it 'returns 0 count' do
      expect(result).to match(a_hash_including({ 'value' => nil }))
    end
  end

  context 'with all filters' do
    let(:variables) do
      {
        path: full_path,
        assigneeUsernames: [assignee.username],
        labelNames: [label.title],
        authorUsername: author.username,
        milestoneTitle: milestone.title,
        from: 20.days.ago.iso8601,
        to: 10.days.ago.iso8601
      }
    end

    it 'returns filtered count' do
      expect(result).to match(a_hash_including({ 'value' => 3 }))
    end
  end
end

RSpec.shared_examples 'value stream analytics flow metrics cycleTime examples' do
  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:label) { create(:group_label, group: group) }

  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }

  let_it_be(:issue1) do
    create(:issue, project: project1, author: author, closed_at: 12.days.ago).tap do |issue|
      issue.metrics.update!(first_mentioned_in_commit_at: 17.days.ago)
    end
  end

  let_it_be(:issue2) do
    create(:issue, project: project2, author: author, closed_at: 13.days.ago).tap do |issue|
      issue.metrics.update!(first_mentioned_in_commit_at: 16.days.ago)
    end
  end

  let_it_be(:issue3) do
    create(:labeled_issue,
      project: project1,
      labels: [label],
      author: author,
      milestone: milestone,
      assignees: [assignee],
      closed_at: 11.days.ago).tap do |issue|
        issue.metrics.update!(first_mentioned_in_commit_at: 14.days.ago)
      end
  end

  let_it_be(:issue4) do
    create(:labeled_issue,
      project: project2,
      labels: [label],
      assignees: [assignee],
      closed_at: 15.days.ago).tap do |issue|
        issue.metrics.update!(first_mentioned_in_commit_at: 20.days.ago)
      end
  end

  before do
    Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute
  end

  let(:query) do
    <<~QUERY
      query($path: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!], $from: Time!, $to: Time!) {
        #{context}(fullPath: $path) {
          flowMetrics {
            cycleTime(assigneeUsernames: $assigneeUsernames, authorUsername: $authorUsername, milestoneTitle: $milestoneTitle, labelNames: $labelNames, from: $from, to: $to) {
              value
              unit
              identifier
              title
              links {
                label
                url
              }
            }
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      path: full_path,
      from: 21.days.ago.iso8601,
      to: 10.days.ago.iso8601
    }
  end

  subject(:result) do
    post_graphql(query, current_user: current_user, variables: variables)

    graphql_data.dig(context.to_s, 'flowMetrics', 'cycleTime')
  end

  it 'returns the correct value' do
    expect(result).to eq({
      'identifier' => 'cycle_time',
      'unit' => n_('day', 'days', 4),
      'value' => 4,
      'title' => _('Cycle Time'),
      'links' => []
    })
  end

  context 'when the user is not authorized' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      expect(result).to eq(nil)
    end
  end

  context 'when outside of the date range' do
    let(:variables) do
      {
        path: full_path,
        from: 30.days.ago.iso8601,
        to: 25.days.ago.iso8601
      }
    end

    it 'returns 0 count' do
      expect(result).to match(a_hash_including({ 'value' => nil }))
    end
  end

  context 'with all filters' do
    let(:variables) do
      {
        path: full_path,
        assigneeUsernames: [assignee.username],
        labelNames: [label.title],
        authorUsername: author.username,
        milestoneTitle: milestone.title,
        from: 20.days.ago.iso8601,
        to: 10.days.ago.iso8601
      }
    end

    it 'returns filtered count' do
      expect(result).to match(a_hash_including({ 'value' => 3 }))
    end
  end
end

RSpec.shared_examples 'value stream analytics flow metrics issuesCompleted examples' do
  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:label) { create(:group_label, group: group) }

  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }

  # we don't care about opened date, only closed date.
  let_it_be(:issue1) do
    create(:issue, project: project1, author: author, created_at: 17.days.ago, closed_at: 12.days.ago)
  end

  let_it_be(:issue2) do
    create(:issue, project: project2, author: author, created_at: 16.days.ago, closed_at: 13.days.ago)
  end

  let_it_be(:issue3) do
    create(:labeled_issue,
      project: project1,
      labels: [label],
      author: author,
      milestone: milestone,
      assignees: [assignee],
      created_at: 14.days.ago,
      closed_at: 11.days.ago)
  end

  let_it_be(:issue4) do
    create(:labeled_issue,
      project: project2,
      labels: [label],
      assignees: [assignee],
      created_at: 20.days.ago,
      closed_at: 15.days.ago)
  end

  before do
    Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute
  end

  let(:query) do
    <<~QUERY
      query($path: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!], $from: Time!, $to: Time!) {
        #{context}(fullPath: $path) {
          flowMetrics {
            issuesCompletedCount(assigneeUsernames: $assigneeUsernames, authorUsername: $authorUsername, milestoneTitle: $milestoneTitle, labelNames: $labelNames, from: $from, to: $to) {
              value
              unit
              identifier
              title
              links {
                label
                url
              }
            }
          }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      path: full_path,
      from: 21.days.ago.iso8601,
      to: 10.days.ago.iso8601
    }
  end

  subject(:result) do
    post_graphql(query, current_user: current_user, variables: variables)

    graphql_data.dig(context.to_s, 'flowMetrics', 'issuesCompletedCount')
  end

  it 'returns the correct value' do
    expect(result).to match(a_hash_including({
      'identifier' => 'issues_completed',
      'unit' => n_('issue', 'issues', 4),
      'value' => 4,
      'title' => _('Issues Completed'),
      'links' => [
        { 'label' => s_('ValueStreamAnalytics|Dashboard'), 'url' => match(/issues_analytics/) },
        { 'label' => s_('ValueStreamAnalytics|Go to docs'), 'url' => match(/definitions/) }
      ]
    }))
  end

  context 'when the user is not authorized' do
    let(:current_user) { create(:user) }

    it 'returns nil' do
      expect(result).to eq(nil)
    end
  end

  context 'when outside of the date range' do
    let(:variables) do
      {
        path: full_path,
        from: 30.days.ago.iso8601,
        to: 25.days.ago.iso8601
      }
    end

    it 'returns 0 count' do
      expect(result).to match(a_hash_including({ 'value' => 0.0 }))
    end
  end

  context 'with all filters' do
    let(:variables) do
      {
        path: full_path,
        assigneeUsernames: [assignee.username],
        labelNames: [label.title],
        authorUsername: author.username,
        milestoneTitle: milestone.title,
        from: 20.days.ago.iso8601,
        to: 10.days.ago.iso8601
      }
    end

    it 'returns filtered count' do
      expect(result).to match(a_hash_including({ 'value' => 1.0 }))
    end
  end
end
