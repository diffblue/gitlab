# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observability rendering', :js, feature_category: :metrics do
  include Spec::Support::Helpers::Features::NotesHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:observable_url) { "https://observe.gitlab.com/" }

  let_it_be(:expected) do
    %(<iframe src="#{observable_url}?theme=light&amp;kiosk" frameborder="0")
  end

  before do
    stub_licensed_features(epics: true)
    group.add_maintainer(user)
    sign_in(user)
  end

  context 'when embedding in an epic' do
    let(:epic) do
      create(:epic, group: group, title: 'Epic to embed', description: observable_url)
    end

    before do
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    it 'renders iframe in description' do
      page.within('.description') do
        expect(page.html).to include(expected)
      end
    end

    it 'renders iframe in comment' do
      expect(page).not_to have_css('.note-text')

      page.within('.js-main-target-form') do
        fill_in('note[note]', with: observable_url)
        click_button('Comment')
      end

      wait_for_requests

      page.within('.note-text') do
        expect(page.html).to include(expected)
      end
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(observability_group_tab: false)
    end

    context 'when embedding in an epic' do
      let(:epic) do
        create(:epic, group: group, title: 'Epic to embed', description: observable_url)
      end

      before do
        visit group_epic_path(group, epic)
        wait_for_requests
      end

      it 'does not render iframe in description' do
        page.within('.description') do
          expect(page.html).not_to include(expected)
          expect(page.html).to include(observable_url)
        end
      end

      it 'does not render iframe in comment' do
        expect(page).not_to have_css('.note-text')

        page.within('.js-main-target-form') do
          fill_in('note[note]', with: observable_url)
          click_button('Comment')
        end

        wait_for_requests

        page.within('.note-text') do
          expect(page.html).not_to include(expected)
          expect(page.html).to include(observable_url)
        end
      end
    end
  end
end
