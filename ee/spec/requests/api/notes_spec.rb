# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Notes, :aggregate_failures, feature_category: :portfolio_management do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, :public) }
  let(:private_user) { create(:user) }

  before do
    project.add_reporter(user)
  end

  context "when noteable is an Epic" do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }
    let!(:epic_note) { create(:note, noteable: epic, project: project, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like "noteable API with confidential notes", 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:noteable) { epic }
      let(:note) { epic_note }
    end

    context 'when issue was promoted to epic' do
      let!(:promoted_issue_epic) { create(:epic, group: group, author: owner, created_at: 1.day.ago) }
      let!(:owner) { create(:group_member, :owner, user: create(:user), group: group).user }
      let!(:reporter) { create(:group_member, :reporter, user: create(:user), group: group).user }
      let!(:guest) { create(:group_member, :guest, user: create(:user), group: group).user }
      let!(:previous_note) { create(:note, :system, noteable: promoted_issue_epic, created_at: 2.days.ago) }
      let!(:previous_note2) { create(:note, :system, noteable: promoted_issue_epic, created_at: 2.minutes.ago) }
      let!(:epic_note) { create(:note, noteable: promoted_issue_epic, author: owner) }

      context 'when user is reporter' do
        it 'returns previous issue system notes' do
          get api("/groups/#{group.id}/epics/#{promoted_issue_epic.id}/notes", reporter)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(3)
        end
      end

      context 'when user is guest' do
        it 'does not return previous issue system notes' do
          get api("/groups/#{group.id}/epics/#{promoted_issue_epic.id}/notes", guest)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(2)
        end
      end
    end
  end
end
