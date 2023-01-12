# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Boards licensed features', :js, feature_category: :team_planning do
  include BoardHelpers

  let_it_be(:user) { create(:user) }

  let(:card) { find('.board:nth-child(1)').find('[data-testid="board_card"]') }

  before do
    stub_feature_flags(apollo_boards: false)
    sign_in user
  end

  context "Project board sidebar" do
    shared_examples "hides group-level licensed features in sidebar" do
      before do
        visit project_board_path(project, board)
        wait_for_requests

        click_card(card)
      end

      it "hides epic widget" do
        expect(page).not_to have_selector('[data-testid="sidebar-epic"]')
      end

      it "hides iteration widget" do
        expect(page).not_to have_selector('[data-testid="iteration-edit"]')
      end
    end

    shared_context "project issue board" do
      let_it_be(:issue) { create(:issue, project: project) }
      let_it_be(:board) { create(:board, project: project) }
      let_it_be(:list) { create(:backlog_list, board: board) }
    end

    context "GitLab SaaS", :saas do
      let_it_be(:plan_license) { :free }
      let_it_be(:global_license) { create(:license) }

      before do
        enable_namespace_license_check!
        allow(License).to receive(:current).and_return(global_license)
        allow(global_license).to receive(:features).and_return([
                                                                 :epics,
                                                                 :iterations
                                                               ])
      end

      context "Public project under Free plan under group namespace" do
        let_it_be(:group) { create(:group, :public) }
        let_it_be(:project) { create(:project, :public, group: group) }
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, :free, namespace: group) }

        include_context "project issue board"

        before do
          group.add_owner(user)
        end

        include_examples "hides group-level licensed features in sidebar"
      end

      context "Public project under Free plan under user namespace" do
        let_it_be(:project) { create(:project, :public, namespace: user.namespace) }
        let_it_be(:gitlab_subscription) { create(:gitlab_subscription, :free, namespace: user.namespace) }

        include_context "project issue board"

        include_examples "hides group-level licensed features in sidebar"
      end
    end
  end
end
