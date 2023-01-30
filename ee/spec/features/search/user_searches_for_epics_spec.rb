# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches for epics', :js, :disable_rate_limiter, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic1) { create(:epic, title: 'Foo', group: group, updated_at: 6.days.ago) }
  let_it_be(:epic2) { create(:epic, :closed, :confidential, title: 'Bar', group: group) }

  def search_for_epic(search)
    fill_in('dashboard_search', with: search)
    find('.gl-search-box-by-click-search-button').click

    select_search_scope('Epics')
  end

  before do
    stub_licensed_features(epics: true)

    group.add_maintainer(user)
    sign_in(user)

    visit(search_path(group_id: group.id))
  end

  include_examples 'top right search form'
  include_examples 'search timeouts', 'epics' do
    let(:additional_params) { { group_id: group.id } }
  end

  it 'finds an epic' do
    search_for_epic(epic1.title)

    page.within('.results') do
      expect(page).to have_link(epic1.title)
      expect(page).to have_text('updated 6 days ago')
      expect(page).not_to have_link(epic2.title)
    end
  end

  it 'hides confidential icon for non-confidential epics' do
    search_for_epic(epic1.title)

    page.within('.results') do
      expect(page).not_to have_css('[data-testid="eye-slash-icon"]')
    end
  end

  it 'shows confidential icon for confidential epics' do
    search_for_epic(epic2.title)

    page.within('.results') do
      expect(page).to have_css('[data-testid="eye-slash-icon"]')
    end
  end

  it 'shows correct badge for open epics' do
    search_for_epic(epic1.title)

    page.within('.results') do
      expect(page).to have_css('.badge-success')
      expect(page).not_to have_css('.badge-info')
    end
  end

  it 'shows correct badge for closed epics' do
    search_for_epic(epic2.title)

    page.within('.results') do
      expect(page).not_to have_css('.badge-success')
      expect(page).to have_css('.badge-info')
    end
  end
end
