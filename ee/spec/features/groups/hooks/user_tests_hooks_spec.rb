# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User tests hooks", :js, feature_category: :integrations do
  include StubRequests

  let!(:group) { create(:group) }
  let!(:hook) { create(:group_hook, group: group) }
  let!(:user) { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  context "when project is not empty" do
    let!(:project) { create(:project, :repository, group: group) }

    context "when URL is valid" do
      before do
        trigger_hook
      end

      it "triggers a hook" do
        expect(page).to have_current_path(group_hooks_path(group), ignore_query: true)
        expect(page).to have_selector('[data-testid="alert-info"]', text: "Hook executed successfully: HTTP 200")
      end
    end

    context "when URL is invalid" do
      before do
        stub_full_request(hook.url, method: :post).to_raise(SocketError.new("Failed to open"))

        click_button('Test')
        click_link('Push events')
      end

      it { expect(page).to have_selector('[data-testid="alert-danger"]', text: "Hook execution failed: Failed to open") }
    end
  end

  context "when project is empty" do
    let!(:project) { create(:project, group: group) }

    before do
      trigger_hook
    end

    it { expect(page).to have_selector('[data-testid="alert-danger"]', text: 'Hook execution failed. Ensure the group has a project with commits.') }
  end

  private

  def trigger_hook
    stub_full_request(hook.url, method: :post).to_return(status: 200)

    click_button('Test')
    click_link('Push events')
  end
end
