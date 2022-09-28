# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'shared/issuable/_approver_suggestion.html.haml' do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { merge_request.author }
  let_it_be(:presenter) { merge_request.present(current_user: user) }

  let(:approvals_available) { true }

  before do
    allow(view).to receive(:can?).with(user, :update_approvers, merge_request).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(presenter).to receive(:approval_feature_available?).and_return(approvals_available)

    assign(:target_project, merge_request.target_project)
  end

  def do_render
    render 'shared/issuable/approver_suggestion', issuable: merge_request, presenter: presenter
  end

  context 'when the approval feature is enabled' do
    let(:approvals_available) { true }

    before do
      assign(:mr_presenter, presenter)

      # used inside the projects/merge_requests/_code_owner_approval_rules partial
      assign(:project, merge_request.target_project)
    end

    it 'renders the MR approvals promo' do
      do_render

      expect(rendered).to have_css('#js-mr-approvals-input')
      expect(view).to render_template('projects/merge_requests/_code_owner_approval_rules')
    end
  end

  context 'when the approval feature is not enabled' do
    let(:approvals_available) { false }

    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan)
    end

    context 'when the check_namespace_plan setting is on' do
      let(:check_namespace_plan) { true }

      before do
        allow(view).to receive(:can?).with(user, :admin_group, anything).and_return(user_can_admin_group)
      end

      context 'when the user is an owner of the root group' do
        let(:user_can_admin_group) { true }

        it 'renders the MR approvals promo' do
          do_render

          expect(rendered).to have_css('#js-mr-approvals-promo')
        end
      end

      context 'when the user is not an owner of the root group' do
        let(:user_can_admin_group) { false }

        it 'renders nothing' do
          do_render

          expect(rendered).to be_blank
        end
      end
    end

    context 'when the check_namespace_plan setting is off' do
      let(:check_namespace_plan) { false }

      it 'renders nothing' do
        do_render

        expect(rendered).to be_blank
      end
    end
  end
end
