# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssuePresenter, feature_category: :portfolio_management do
  include Gitlab::Routing.url_helpers

  let(:user)         { create(:user) }
  let(:group)        { create(:group) }
  let(:project)      { create(:project, group: group) }
  let(:epic)         { create(:epic, group: group) }
  let(:issue)        { create(:issue, project: project) }
  let!(:epic_issue)  { create(:epic_issue, issue: issue, epic: epic) }
  let(:target_issue) { epic.issues_readable_by(user).first }
  let(:presenter)    { described_class.new(target_issue, current_user: user) }

  before do
    stub_licensed_features(epics: true)
    group.add_guest(user)
  end

  describe '#group_epic_issue_path' do
    it 'returns correct path' do
      expect(presenter.group_epic_issue_path(user)).to eq "/groups/#{group.name}/-/epics/#{epic.iid}/issues/#{target_issue.epic_issue_id}"
    end

    it 'returns nil without proper permission' do
      unauth_user = create(:user)

      expect(presenter.group_epic_issue_path(unauth_user)).to be_nil
    end
  end
end
