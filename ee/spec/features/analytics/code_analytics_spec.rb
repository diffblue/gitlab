# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CodeReviewAnalytics', :js, feature_category: :devops_reports do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:auditor) { create(:user, auditor: true) }

  before do
    stub_licensed_features(code_review_analytics: true)

    project.add_developer(user)
  end

  context 'filtered search' do
    before do
      sign_in(user)

      visit project_analytics_code_reviews_path(project)
    end

    it 'renders the filtered search bar correctly' do
      page.within('.content-wrapper .content .vue-filtered-search-bar-container') do
        expect(page).to have_selector('.gl-search-box-by-click')
        expect(page.find('.gl-filtered-search-term-input')[:placeholder]).to eq('Filter results')
      end
    end

    it 'displays label and milestone in search hint' do
      page.within('.content-wrapper .content .vue-filtered-search-bar-container') do
        page.find('.gl-search-box-by-click').click

        expect(page).to have_selector('.gl-filtered-search-suggestion-list')

        hints = page.find_all('.gl-filtered-search-suggestion-list > li')

        expect(hints.length).to eq(2)
        expect(hints[0]).to have_content('Milestone')
        expect(hints[1]).to have_content('Label')
      end
    end
  end

  shared_examples 'empty state' do |expect_button:|
    it "shows empty state #{expect_button ? 'with' : 'without'} \"New merge request\" button" do
      visit project_analytics_code_reviews_path(project)

      expect(page).to have_content("You don't have any open merge requests")

      if expect_button
        expect(page).to have_link('New merge request')
      else
        expect(page).not_to have_link('New merge request')
      end
    end
  end

  context 'empty state' do
    context 'when a regular user is signed in' do
      before do
        sign_in(user)
      end

      it_behaves_like 'empty state', expect_button: true
    end

    context 'when an "Auditor" is signed in' do
      before do
        sign_in(auditor)
      end

      context 'when "Auditor" is a member of the project' do
        before do
          project.add_developer(auditor)
        end

        it_behaves_like 'empty state', expect_button: true
      end

      context 'when "Auditor" is not a member of the project' do
        it_behaves_like 'empty state', expect_button: false
      end
    end

    context 'when no user is signed in' do
      it_behaves_like 'empty state', expect_button: false
    end
  end
end
