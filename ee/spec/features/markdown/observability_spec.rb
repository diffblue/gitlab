# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observability rendering', :js, feature_category: :metrics do
  include Features::NotesHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }

  let_it_be(:observable_url) { "https://www.gitlab.com/groups/#{group.path}/-/observability/explore?observability_path=/explore?foo=bar" }

  let_it_be(:expected_observable_url) { "https://observe.gitlab.com/-/#{group.id}/explore?foo=bar" }

  before do
    stub_config_setting(url: "https://www.gitlab.com")
    stub_licensed_features(epics: true)
    group.add_developer(user)
    sign_in(user)
  end

  context 'when embedding in an epic' do
    let(:epic) do
      create(:epic, group: group, title: 'Epic to embed', description: observable_url)
    end

    context 'when user is a developer of the embedded group' do
      before do
        visit group_epic_path(group, epic)
        wait_for_requests
      end

      it_behaves_like 'embeds observability'
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(observability_group_tab: false)
        visit group_epic_path(group, epic)
        wait_for_requests
      end

      it_behaves_like 'does not embed observability'
    end
  end
end
