# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsHelper do
  describe '#render_items_list' do
    it "returns one item in the list" do
      expect(render_items_list(["user"])).to eq("user")
    end

    it "returns two items in the list" do
      expect(render_items_list(%w(user user1))).to eq("user and user1")
    end

    it "returns three items in the list" do
      expect(render_items_list(%w(user user1 user2))).to eq("user, user1 and user2")
    end
  end

  describe '#diffs_tab_pane_data' do
    it 'returns data' do
      project = build_stubbed(:project)
      merge_request = build_stubbed(:merge_request, project: project)

      allow(helper).to receive(:current_user).and_return(build_stubbed(:user))

      expect(helper.diffs_tab_pane_data(project, merge_request, {})).to include({
        show_generate_test_file_button: 'false'
      })
    end
  end
end
