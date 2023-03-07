# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::DuplicateService, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:canonical_project) { create(:project) }
  let(:duplicate_project) { create(:project) }

  let(:canonical_issue) { create(:issue, project: canonical_project) }
  let(:duplicate_issue) { create(:issue, project: duplicate_project) }

  subject { described_class.new(container: duplicate_project, current_user: user) }

  describe '#execute' do
    it 'relates the duplicate issues' do
      canonical_project.add_reporter(user)
      duplicate_project.add_reporter(user)

      subject.execute(duplicate_issue, canonical_issue)

      issue_link = IssueLink.last
      expect(issue_link.source).to eq(duplicate_issue)
      expect(issue_link.target).to eq(canonical_issue)
    end
  end
end
