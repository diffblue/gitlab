# frozen_string_literal: true

RSpec.shared_examples_for 'MR checks settings' do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_owner(user)
    stub_licensed_features(group_level_merge_checks_setting: true)
  end

  context 'when checkboxes are not locked', :js do
    it 'shows initial status' do
      visit(merge_requests_settings_path)

      expect(page).not_to have_selector(
        '[data-testid="allow_merge_if_pipeline_succeeds_checkbox"]>input[disabled]'
      )
      expect(page).to have_selector('[data-testid="allow_merge_on_skipped_pipeline_checkbox"]>input[disabled]')
      expect(page).not_to have_selector(
        '[data-testid="allow_merge_if_all_discussions_are_resolved_checkbox"]>input[disabled]'
      )
    end
  end

  context 'when checkboxes are locked', :js do
    before do
      group.namespace_settings.update!(
        only_allow_merge_if_pipeline_succeeds: true,
        allow_merge_on_skipped_pipeline: true,
        only_allow_merge_if_all_discussions_are_resolved: true
      )
    end

    it 'shows disabled status' do
      checkboxs_selectors = %w[
        [data-testid="allow_merge_if_pipeline_succeeds_checkbox"]>input[disabled]
        [data-testid="allow_merge_on_skipped_pipeline_checkbox"]>input[disabled]
        [data-testid="allow_merge_if_all_discussions_are_resolved_checkbox"]>input[disabled]
      ]

      visit(merge_requests_settings_path)

      checkboxs_selectors.each do |selector|
        expect(page).to have_selector(selector)
        expect(page.find(selector)).to be_checked
      end
    end
  end
end
