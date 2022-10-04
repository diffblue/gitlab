# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Epic', :js do
  let(:user) { create(:user) }
  let(:epic) { create(:epic) }

  before do
    stub_licensed_features(epics: true)
    epic.group.add_maintainer(user)
    sign_in(user)

    visit group_epic_path(epic.group, epic)
  end

  it_behaves_like 'thread comments for issue, epic and merge request', 'epic'
end
