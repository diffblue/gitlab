# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observability rendering', :js, feature_category: :metrics do
  include Spec::Support::Helpers::Features::NotesHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:observable_url) { "https://observe.gitlab.com/#{group.id}/some-dashboard" }

  let_it_be(:expected) do
    %(<iframe src="#{observable_url}?theme=light&amp;kiosk" frameborder="0")
  end

  before do
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

    context 'when user is not a developer of the embedded group' do
      before do
        visit group_epic_path(group, epic)
        wait_for_requests
      end

      it_behaves_like 'does not embed observability' do
        let_it_be(:observable_url) { "https://observe.gitlab.com/1234/some-dashboard" }
      end
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
