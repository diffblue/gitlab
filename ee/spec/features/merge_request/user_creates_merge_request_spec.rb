# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User creates a merge request", :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include CookieHelper
  include ListboxHelpers

  let(:approver) { create(:user) }
  let(:project) do
    create(:project, :repository, merge_requests_template: template_text)
  end

  let(:template_text) { "This merge request should contain the following." }
  let(:title) { "Some feature" }
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user2)
    project.add_maintainer(approver)
    sign_in(user)
    set_cookie('new-actions-popover-viewed', 'true')

    stub_licensed_features(merge_request_approvers: true)
    create(:approval_project_rule, project: project, users: [approver])

    visit(project_new_merge_request_path(project))
  end

  context 'when the user has branches in an SSO enforced group' do
    let_it_be(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: true) }
    let_it_be(:restricted_group) { create(:group, saml_provider: saml_provider) }
    let_it_be(:canonical_project) { create(:project, :private, :repository, group: restricted_group) }
    let_it_be(:user) { create(:user) }

    let(:target_project) do
      fork_project(canonical_project, user,
        repository: true,
        namespace: user.namespace)
    end

    let(:message) do
      "GroupSAML|Some branches are inaccessible because your SAML session has expired. " \
        "To access the branches, select the group’s path to reauthenticate."
    end

    before do
      stub_licensed_features(group_saml: true)

      create(:group_saml_identity, user: user, saml_provider: saml_provider)

      restricted_group.add_owner(user)

      sign_in(user)
    end

    context 'and the session is not active' do
      it 'shows the user an alert', :aggregate_failures do
        visit project_new_merge_request_path(target_project)

        expect(page).to have_content(s_(message))
      end

      it 'lets the user click the alert to sign in', :aggregate_failures, :js do
        visit project_new_merge_request_path(target_project)

        expect(page).to have_link(href: %r{/groups/#{restricted_group.name}/-/saml})
      end

      context 'with the `hide_unaccessible_saml_branches` feature flag on' do
        it 'will not show any inaccessible branches in the dropdown', :aggregate_failures, :js do
          visit project_new_merge_request_path(target_project)

          find(".js-target-project").click

          wait_for_requests

          expect_no_listbox_item(canonical_project.full_path.to_s)
        end
      end

      context 'with the `hide_unaccessible_saml_branches` feature flag off' do
        before do
          stub_feature_flags(hide_unaccessible_saml_branches: false)
        end

        it 'will not show any inaccessible branches in the dropdown', :aggregate_failures, :js do
          visit project_new_merge_request_path(target_project)

          find(".js-target-project").click

          wait_for_requests

          expect_listbox_item(canonical_project.full_path.to_s)
        end
      end
    end

    context 'and the session is active' do
      it 'does not show the user an alert', :aggregate_failures do
        dummy_session = { active_group_sso_sign_ins: { saml_provider.id => DateTime.now } }
        allow(Gitlab::Session).to receive(:current).and_return(dummy_session)

        visit project_new_merge_request_path(target_project)

        expect(page).not_to have_content(s_(message))
      end
    end
  end

  it "creates a merge request" do
    allow_next_instance_of(Gitlab::AuthorityAnalyzer) do |instance|
      allow(instance).to receive(:calculate).and_return([user2])
    end

    find(".js-source-branch").click

    find('.gl-listbox-search-input').set('fix')

    wait_for_requests

    find('.gl-new-dropdown-item-text-wrapper', text: 'fix', match: :first).click

    find(".js-target-branch").click

    find('.gl-listbox-search-input').set('feature')

    wait_for_requests

    find('.gl-new-dropdown-item-text-wrapper', text: 'feature', match: :first).click

    click_button("Compare branches")

    expect(find_field("merge_request_description").value).to eq(template_text)

    click_button 'Approval rules'

    page.within('.js-approval-rules') do
      expect(page).to have_css("img[alt=\"#{approver.name}\"]")
    end

    # TODO: Fix https://gitlab.com/gitlab-org/gitlab/issues/11527
    # page.within(".suggested-approvers") do
    #   expect(page).to have_content(user2.name)
    # end
    #
    # click_link(user2.name)
    #
    # page.within("ul.approver-list") do
    #   expect(page).to have_content(user2.name)
    # end

    fill_in("Title", with: title)
    click_button("Create merge request")

    wait_for_requests

    page.within(".js-issuable-actions") do
      click_link("Edit", match: :first)
    end

    # page.within("ul.approver-list") do
    #   expect(page).to have_content(user2.name)
    # end
  end
end
