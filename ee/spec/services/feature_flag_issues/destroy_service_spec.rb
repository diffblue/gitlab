# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlagIssues::DestroyService, feature_category: :feature_flags do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  before_all do
    project.add_developer(developer)
    project.add_reporter(reporter)
  end

  before do
    stub_licensed_features(feature_flags_related_issues: true)
  end

  def setup
    feature_flag = create(:operations_feature_flag, project: project)
    issue = create(:issue, project: project)
    create(:feature_flag_issue, feature_flag: feature_flag, issue: issue)
  end

  describe '#execute' do
    it 'unlinks the feature flag and the issue' do
      feature_flag_issue = setup

      described_class.new(feature_flag_issue, developer).execute

      expect(::FeatureFlagIssue.count).to eq(0)
    end

    it 'does not unlink the feature flag and the issue when the user cannot admin the feature flag' do
      feature_flag_issue = setup

      described_class.new(feature_flag_issue, reporter).execute

      expect(::FeatureFlagIssue.count).to eq(1)
    end
  end
end
