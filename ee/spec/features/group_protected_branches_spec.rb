# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group-level Protected Branches', :js, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:visit_page) { group_settings_repository_path(group) }

  let_it_be(:protected_branch) do
    create(
      :protected_branch,
      :maintainers_can_merge,
      :maintainers_can_push,
      project: nil,
      group: group,
      allow_force_push: false,
      code_owner_approval_required: true
    )
  end

  let(:feature_flag_group_protected_branches) { true }
  let(:ff_allow_protected_branches_for_group) { true }
  let(:license_group_protected_branches) { true }
  let(:license_code_owner_approval_required) { true }
  let(:permission_admin_group) { true }

  let(:container) { page.find('#js-protected-branches-settings') }
  let(:new_container) { container.find('.new-protected-branch') }
  let(:list_container) { container.find('.protected-branches-list') }

  before do
    stub_feature_flags(group_protected_branches: feature_flag_group_protected_branches)
    stub_feature_flags(allow_protected_branches_for_group: ff_allow_protected_branches_for_group)
    stub_licensed_features(
      group_protected_branches: license_group_protected_branches,
      code_owner_approval_required: license_code_owner_approval_required
    )
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, :admin_group, group).and_return(permission_admin_group)

    group.add_owner(user)
    sign_in(user)

    visit visit_page
  end

  describe 'group level protected branches feature disabled' do
    context 'when feature flag disabled' do
      let(:feature_flag_group_protected_branches) { false }
      let(:ff_allow_protected_branches_for_group) { false }

      it 'does not render protected branches section' do
        expect(page).not_to have_css('#js-protected-branches-settings')
      end
    end

    context 'when license is not available' do
      let(:license_group_protected_branches) { false }

      it 'does not render protected branches section' do
        expect(page).not_to have_css('#js-protected-branches-settings')
      end
    end

    context 'when user has no permission' do
      let(:permission_admin_group) { false }

      it 'does not render protected branches section' do
        expect(page).not_to have_css('#js-protected-branches-settings')
      end
    end

    context 'when is not top group' do
      let(:group) { create(:group, :nested) }

      it 'does not render protected branches section' do
        visit group_settings_repository_path(group)

        expect(page).not_to have_css('#js-protected-branches-settings')
      end
    end
  end

  describe 'feature `code_owner_approval` disabled' do
    let(:license_code_owner_approval_required) { false }

    it 'has no `code_owner_approval` form field' do
      expect(new_container).not_to have_css('.js-code-owner-toggle')
      expect(list_container).not_to have_css('.js-code-owner-toggle')
    end
  end

  describe 'create protected branch' do
    let(:branch_input) { new_container.find('#protected_branch_name') }
    let(:allowed_to_merge_input) { new_container.find('.js-allowed-to-merge') }
    let(:allowed_to_push_input) { new_container.find('.js-allowed-to-push') }
    let(:force_push_toggle) { new_container.find('.js-force-push-toggle').find('button') }
    let(:code_owner_toggle) { new_container.find('.js-code-owner-toggle').find('button') }

    let(:branch_name) { 'branch-name' }
    let(:merge_access) { 'Maintainers' }
    let(:push_access) { 'No one' }

    it 'created successfully' do
      branch_input.fill_in with: branch_name

      update_protected_branch_form(real_time_request: false)

      click_on 'Protect'
      wait_for_requests

      protected_branch = group.protected_branches.last
      expect(protected_branch.values_at(:name, :allow_force_push, :code_owner_approval_required)).to eq([
        branch_name,
        true,
        false
      ])
      expect(protected_branch.merge_access_levels.map(&:humanize)).to match_array([merge_access])
      expect(protected_branch.push_access_levels.map(&:humanize)).to match_array([push_access])
    end
  end

  describe 'update protected branch' do
    let(:branch_input) { list_container.find('.ref-name') }
    let(:allowed_to_merge_input) { list_container.find('.js-allowed-to-merge') }
    let(:allowed_to_push_input) { list_container.find('.js-allowed-to-push') }
    let(:force_push_toggle) { list_container.find('.js-force-push-toggle').find('button') }
    let(:code_owner_toggle) { list_container.find('.js-code-owner-toggle').find('button') }

    let(:merge_access) { 'No one' }
    let(:push_access) { 'No one' }

    it 'updated successfully' do
      expect(branch_input).to have_text(protected_branch.name)

      update_protected_branch_form(real_time_request: true)

      protected_branch.reload

      expect(protected_branch.values_at(:allow_force_push, :code_owner_approval_required)).to eq([
        true,
        false
      ])
      expect(protected_branch.merge_access_levels.map(&:humanize)).to match_array([merge_access])
      expect(protected_branch.push_access_levels.map(&:humanize)).to match_array([push_access])
    end
  end

  describe 'delete protected branch' do
    let(:unprotect_button) { list_container.find('a', text: 'Unprotect') }
    let(:confirm_button) { page.find('#confirmationModal .js-modal-action-primary') }

    it 'deleted successfully' do
      unprotect_button.click
      confirm_button.click
      wait_for_requests
      sleep 1

      expect { protected_branch.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  def update_protected_branch_form(real_time_request: false)
    allowed_to_merge_input.click
    wait_for_requests
    page.find('.dropdown.show').click_on merge_access
    wait_for_requests if real_time_request

    allowed_to_push_input.click
    wait_for_requests
    page.find('.dropdown.show').click_on push_access
    wait_for_requests if real_time_request

    force_push_toggle.click
    wait_for_requests if real_time_request
    expect(force_push_toggle[:class]).to include("is-checked")

    code_owner_toggle.click
    wait_for_requests if real_time_request
    expect(code_owner_toggle[:class]).not_to include("is-checked")
  end
end
