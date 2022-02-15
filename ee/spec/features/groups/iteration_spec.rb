# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group iterations' do
  let_it_be(:title_selector) { 'iteration-title' }
  let_it_be(:description_selector) { '#iteration-description' }
  let_it_be(:start_date_selector) { '#iteration-start-date' }
  let_it_be(:due_date_selector) { '#iteration-due-date' }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project_empty_repo, group: group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }

  around do |example|
    freeze_time { example.run }
  end

  before do
    sign_in(user)
  end

  context 'create an iteration', :js do
    before do
      visit new_group_iteration_path(group)
    end

    it 'renders description preview' do
      description = find(description_selector)
      description.native.send_keys('')
      click_link('Preview')
      preview = find('.js-vue-md-preview')

      expect(preview).to have_content('Nothing to preview.')

      click_link('Write')
      description.native.send_keys(':+1: Nice')
      click_link('Preview')

      expect(preview).to have_css('gl-emoji')
      expect(find('#iteration-description', visible: false)).not_to be_visible
    end

    it 'description input does not support autocomplete' do
      description = find(description_selector)
      description.native.send_keys('!')

      expect(page).not_to have_selector('.atwho-view')
    end
  end
end
