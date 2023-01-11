# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceIterationEvent, :snowplow, feature_category: :team_planing, type: :model do
  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
  it_behaves_like 'a note for work item resource event'

  it_behaves_like 'having unique enum values'
  it_behaves_like 'timebox resource event validations'
  it_behaves_like 'timebox resource event actions'
  it_behaves_like 'timebox resource tracks issue metrics', :iteration

  # Move inside timebox_resource_tracks_issue_metrics when milestone is migrated
  # from https://gitlab.com/gitlab-org/gitlab/-/issues/365960
  describe 'when creating an issue' do
    let(:issue) { create(:issue) }

    it_behaves_like 'issue_edit snowplow tracking' do
      let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_ITERATION_CHANGED }
      let(:project) { issue.project }
      let(:user) { issue.author }
      subject(:service_action) { create(described_class.name.underscore.to_sym, issue: issue) }
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:iteration) }
  end
end
