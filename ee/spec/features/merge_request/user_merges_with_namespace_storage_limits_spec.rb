# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Merge request > User merges with namespace storage limits", :js, :saas, :sidekiq_inline,
  feature_category: :code_review_workflow do
  include NamespaceStorageHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let!(:project) { create(:project, :repository, group: group) }
  let!(:merge_request) { create(:merge_request, source_project: project) }

  before_all do
    create(:gitlab_subscription, :premium, namespace: group)
    create(:namespace_root_storage_statistics, namespace: group)
  end

  before do
    project.add_developer(user)
    enforce_namespace_storage_limit(group)
    set_enforcement_limit(group, megabytes: 10)
    sign_in(user)
  end

  context 'when the namespace storage limit has not been exceeded' do
    before do
      set_used_storage(group, megabytes: 4)
    end

    it 'merges the merge request' do
      visit(merge_request_path(merge_request))

      click_merge_button

      expect(page).to have_selector('.gl-badge', text: 'Merged')
    end
  end

  context 'when the namespace storage limit has been exceeded' do
    before do
      set_used_storage(group, megabytes: 15)
    end

    it 'does not merge the merge request' do
      visit(merge_request_path(merge_request))

      click_merge_button

      expect(page).to have_text(
        'Your namespace storage is full. ' \
        'This merge request cannot be merged. ' \
        'To continue, manage your storage usage'
      )
    end
  end

  def click_merge_button
    page.within(".mr-state-widget") do
      click_button("Merge")
    end
  end
end
