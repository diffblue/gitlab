# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicsHelper, type: :helper do
  include ApplicationHelper

  describe '#epic_new_app_data' do
    let(:group) { create(:group) }

    it 'returns the correct data for a new epic' do
      expected_data = {
        group_path: group.full_path,
        group_epics_path: "/groups/#{group.full_path}/-/epics",
        labels_fetch_path: "/groups/#{group.full_path}/-/labels.json?include_ancestor_groups=true&only_group_labels=true",
        labels_manage_path: "/groups/#{group.full_path}/-/labels",
        markdown_preview_path: "/groups/#{group.full_path}/preview_markdown",
        markdown_docs_path: help_page_path('user/markdown')
      }

      expect(helper.epic_new_app_data(group)).to match(hash_including(expected_data))
    end
  end
end
