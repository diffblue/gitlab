# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/project_members/index', :aggregate_failures, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) } # rubocop:todo RSpec/FactoryBot/AvoidCreate
  let_it_be(:project, reload: true) do
    create(:project, :empty_repo, :with_namespace_settings).present(current_user: user) # rubocop:todo RSpec/FactoryBot/AvoidCreate
  end

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
        expect(rendered).to have_selector('.js-invite-groups-modal')
        expect(rendered).not_to have_selector('.js-invite-members-trigger')
        expect(rendered).not_to have_content('Members can be added by project')
        expect(response).to render_template(partial: 'projects/_invite_groups_modal')
      end

      context 'when project can not be shared' do
        before do
          project.namespace.share_with_group_lock = true
        end

        it 'renders as expected' do
          render

          expect(rendered).to have_content('Project members')
          expect(rendered).not_to have_content('You can invite')
          expect(rendered).not_to have_selector('.js-invite-group-trigger')
          expect(response).not_to render_template(partial: 'projects/_invite_groups_modal')
        end
      end
    end

    context 'when managing members text is present' do
      let_it_be(:project) { create(:project, group: create(:group)) } # rubocop:todo RSpec/FactoryBot/AvoidCreate

      before do
        allow(view).to receive(:can?).with(user, :admin_group_member, project.root_ancestor).and_return(true)
        allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement, project.root_ancestor) do |instance|
          allow(instance).to receive(:enforce_cap?).and_return(true)
        end
      end

      it 'renders as expected' do
        render

        expect(rendered).to have_content('Project members')
        expect(rendered).to have_content('You can invite a new member to')

        expect(rendered).to have_content(
          'To manage seats for all members associated with this group and its subgroups'
        )

        expect(rendered).to have_link('usage quotas page', href: group_usage_quotas_path(project.root_ancestor))
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
