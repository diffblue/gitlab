# frozen_string_literal: true

RSpec.shared_examples "protected branches > access control > EE" do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:no_one) { ProtectedRef::AccessLevel.humanize(::Gitlab::Access::NO_ACCESS) }
  let_it_be(:roles) { ProtectedRef::AccessLevel.human_access_levels.except(::Gitlab::Access::NO_ACCESS) }
  let_it_be(:edit_form) { '.js-protected-branch-edit-form' }

  %w[merge push].each do |git_operation|
    context "for operation: #{git_operation}" do
      # Need to set a default for the `git_operation` access level that _isn't_ being tested
      let(:other_git_operation) { git_operation == 'merge' ? 'push' : 'merge' }
      let(:users) { create_list(:user, 5) }
      let(:groups) { create_list(:group, 5) }

      before do
        users.each { |user| project.add_developer(user) }
        groups.each do |group|
          project.project_group_links.create(group: group, group_access: ::Gitlab::Access::DEVELOPER) # rubocop:disable Rails/SaveBang
        end
      end

      it "allows creating protected branches that roles, users, and groups can #{git_operation} to" do
        visit project_protected_branches_path(project)

        set_protected_branch_name('master')
        set_allowed_to(git_operation, roles.values)
        set_allowed_to(git_operation, groups.map(&:name))
        set_allowed_to(git_operation, users.map(&:name))
        set_allowed_to(other_git_operation)

        click_on_protect

        within(".protected-branches-list") { expect(page).to have_content('master') }
        expect(ProtectedBranch.count).to eq(1)
        access_levels = ProtectedBranch.last.public_send("#{git_operation}_access_levels")
        allowed_access_levels = access_levels.map(&:access_level)
        user_ids = access_levels.map(&:user_id)
        group_ids = access_levels.map(&:group_id)

        roles.each { |(access_type_id, _)| expect(allowed_access_levels).to include(access_type_id) }
        groups.each { |group| expect(group_ids).to include(group.id) }
        users.each { |user| expect(user_ids).to include(user.id) }
      end

      it "allows updating protected branches so that roles and users can #{git_operation} to it" do
        visit project_protected_branches_path(project)
        set_protected_branch_name('master')
        set_allowed_to('merge')
        set_allowed_to('push')

        click_on_protect

        set_allowed_to(git_operation, roles.values, form: edit_form)
        set_allowed_to(git_operation, groups.map(&:name), form: edit_form)
        set_allowed_to(git_operation, users.map(&:name), form: edit_form)

        wait_for_requests

        expect(ProtectedBranch.count).to eq(1)

        access_levels = ProtectedBranch.last.public_send("#{git_operation}_access_levels")
        allowed_access_levels = access_levels.map(&:access_level)
        user_ids = access_levels.map(&:user_id)
        group_ids = access_levels.map(&:group_id)

        roles.each { |(access_type_id, _)| expect(allowed_access_levels).to include(access_type_id) }
        groups.each { |group| expect(group_ids).to include(group.id) }
        users.each { |user| expect(user_ids).to include(user.id) }
      end

      it "allows updating protected branches so that roles and users cannot #{git_operation} to it" do
        visit project_protected_branches_path(project)
        set_protected_branch_name('master')

        set_allowed_to(git_operation, roles.values)
        set_allowed_to(git_operation, groups.map(&:name))
        set_allowed_to(git_operation, users.map(&:name))
        set_allowed_to(other_git_operation)

        click_on_protect

        set_allowed_to(git_operation, roles.values, form: edit_form)
        set_allowed_to(git_operation, groups.map(&:name), form: edit_form)
        set_allowed_to(git_operation, users.map(&:name), form: edit_form)

        wait_for_requests

        expect(ProtectedBranch.count).to eq(1)

        access_levels = ProtectedBranch.last.public_send("#{git_operation}_access_levels")
        expect(access_levels).to be_empty
      end

      it "prepends selected users that can #{git_operation} to" do
        users = create_list(:user, 21)
        users.each { |user| project.add_developer(user) }

        visit project_protected_branches_path(project)

        # Create Protected Branch
        set_protected_branch_name('master')
        set_allowed_to(git_operation, roles.values)
        set_allowed_to(other_git_operation)

        click_on_protect

        # Update Protected Branch
        within(".protected-branches-list") do
          within_select(".js-allowed-to-#{git_operation}") do
            %w[Roles Groups Users].each do |header|
              expect(page).to have_selector('.dropdown-header', text: header)
            end

            find(".dropdown-input-field").set(users.last.name) # Find a user that is not loaded
            wait_for_requests

            click_on users.last.name
          end

          wait_for_requests

          within_select(".js-allowed-to-#{git_operation}") do
            wait_for_requests
            # Verify the user is appended in the dropdown
            expect(page).to have_selector '.dropdown-content .is-active', text: users.last.name
          end
        end

        expect(ProtectedBranch.count).to eq(1)
        access_levels = ProtectedBranch.last.public_send("#{git_operation}_access_levels")
        allowed_access_levels = access_levels.map(&:access_level)
        user_ids = access_levels.map(&:user_id)

        roles.each { |(access_type_id, _)| expect(allowed_access_levels).to include(access_type_id) }
        expect(user_ids).to include(users.last.id)
      end
    end
  end

  context 'When updating a protected branch' do
    it 'discards other roles when choosing "No one"' do
      visit project_protected_branches_path(project)
      set_protected_branch_name('fix')
      set_allowed_to('merge')
      set_allowed_to('push', roles.values)
      click_on_protect

      allowed_access_levels = ProtectedBranch.last.push_access_levels.map(&:access_level)
      roles.each { |(access_type_id, _)| expect(allowed_access_levels).to include(access_type_id) }
      expect(allowed_access_levels).not_to include(::Gitlab::Access::NO_ACCESS)

      set_allowed_to('push', no_one, form: edit_form)
      wait_for_requests

      allowed_access_levels = ProtectedBranch.last.push_access_levels.map(&:access_level)
      roles.each { |(access_type_id, _)| expect(allowed_access_levels).not_to include(access_type_id) }
      expect(allowed_access_levels).to include(::Gitlab::Access::NO_ACCESS)
    end
  end

  context 'When creating a protected branch' do
    it 'discards other roles when choosing "No one"' do
      visit project_protected_branches_path(project)
      set_protected_branch_name('master')
      set_allowed_to('merge')
      set_allowed_to('push', roles.values)
      set_allowed_to('push', no_one)
      click_on_protect

      allowed_access_levels = ProtectedBranch.last.push_access_levels.map(&:access_level)
      roles.each { |(access_type_id, _)| expect(allowed_access_levels).not_to include(access_type_id) }
      expect(allowed_access_levels).to include(::Gitlab::Access::NO_ACCESS)
    end
  end

  describe 'protected branch restrictions' do
    let!(:protected_branch) { create(:protected_branch, project: project) }

    before do
      stub_licensed_features(unprotection_restrictions: true)
    end

    it 'unprotect/delete can be performed by a maintainer' do
      visit project_protected_branches_path(project)

      expect(page).to have_selector('[data-testid="protected-branch"]')
      accept_gl_confirm(button_text: 'Unprotect branch') { click_on 'Unprotect' }
      expect(page).not_to have_selector('[data-testid="protected-branch"]')
    end
  end
end
