# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/project_members/index', :aggregate_failures do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { ProjectPresenter.new(create(:project, :empty_repo), current_user: user) }

  before do
    allow(view).to receive(:project_members_app_data_json).and_return({})
    allow(view).to receive(:current_user).and_return(user)
    assign(:project, project)
  end

  context 'when user can invite members for the project' do
    before do
      project.add_maintainer(user)
    end

    context 'when membership is locked' do
      before do
        allow(view).to receive(:membership_locked?).and_return(true)
      end

      it 'renders as expected' do
        render

        expect(rendered).to have_content('Project members')
        expect(rendered).to have_content('You can invite another group to')
        expect(rendered).not_to have_link('Import from a project')
        expect(rendered).to have_selector('.js-invite-group-trigger')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
        expect(rendered).not_to have_content('Members can be added by project')
        expect(response).to render_template(partial: 'projects/_invite_members_modal')
      end

      context 'when project can not be shared' do
        before do
          project.namespace.share_with_group_lock = true
        end

        it 'renders as expected' do
          render

          expect(rendered).to have_content('Project members')
          expect(rendered).not_to have_content('You can invite')
          expect(response).to render_template(partial: 'projects/_invite_members_modal')
        end
      end
    end
  end

  context 'when user can not invite members or group for the project' do
    context 'when membership is locked and project can not be shared' do
      before do
        allow(view).to receive(:membership_locked?).and_return(true)
        project.namespace.share_with_group_lock = true
      end

      it 'renders as expected' do
        render

        expect(rendered).not_to have_content('Project members')
        expect(rendered).not_to have_content('Members can be added by project')
      end
    end
  end
end
