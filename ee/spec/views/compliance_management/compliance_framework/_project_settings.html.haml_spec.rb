# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'compliance_management/compliance_framework/_project_settings.html.haml' do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:project) { create(:project, :with_compliance_framework, namespace: group) }

  before do
    allow(view).to receive(:current_user).and_return(group_owner)
    allow(view).to receive(:expanded).and_return(true)
    allow(group_owner).to receive(:can?).and_return(true)
    assign(:project, project)
    stub_licensed_features(custom_compliance_frameworks: true)
  end

  it 'shows the section description' do
    render

    expect(rendered).to have_text 'Select a compliance framework to apply to this project. How are these added?'
  end

  context 'group has compliance frameworks' do
    let_it_be(:framework) { create(:compliance_framework, namespace: group, name: 'Custom framework 23') }

    it 'includes a dropdown including that framework' do
      render

      expect(rendered).to have_select('project[compliance_framework_setting_attributes][framework]', with_options: ['Custom framework 23'])
    end

    it 'shows the submit button' do
      render

      expect(rendered).to have_button('Save changes')
    end

    context 'user is group maintainer' do
      let_it_be(:maintainer) { create(:user) }

      before do
        group.add_maintainer(maintainer)
        allow(view).to receive(:current_user).and_return(maintainer)
      end

      it 'shows the no permissions text' do
        render

        expect(rendered).to have_text('Owners can modify this selection.')
      end

      it 'disables the dropdown' do
        render

        expect(rendered).to have_css('input[id=project_compliance_framework_setting_attributes_framework][disabled="disabled"]')
      end

      it 'hides the submit button' do
        expect(rendered).not_to have_button('Save changes')
      end
    end

    context 'project does not have a gitlab_ci_yml file' do
      before do
        allow(project.repository).to receive(:gitlab_ci_yml).and_return(nil)
      end

      it 'does not render the No pipeline alert' do
        render

        expect(rendered).to have_content('No pipeline configuration found')
      end
    end

    context 'project has a gitlab_ci_yml file' do
      before do
        allow(project.repository).to receive(:gitlab_ci_yml).and_return('test: scriptx: exit 0')
      end

      it 'does render the No pipeline alert' do
        render

        expect(rendered).not_to have_content('No pipeline configuration found')
      end
    end
  end

  context 'group has no compliance frameworks' do
    before do
      group.compliance_management_frameworks.delete_all
    end

    it 'renders the empty state' do
      render

      expect(rendered).to have_css(
        '#js-project-compliance-framework-empty-state'\
          "[data-add-framework-path=\"#{edit_group_path(group)}#js-compliance-frameworks-settings\"]"\
          "[data-empty-state-svg-path]"\
          "[data-group-name=\"#{group.name}\"]"\
          "[data-group-path=\"#{group_path(group)}\"]"
      )
    end

    it 'hides the submit button' do
      expect(rendered).not_to have_button('Save changes')
    end

    context 'user is group maintainer' do
      let_it_be(:maintainer) { create(:user) }

      before do
        group.add_maintainer(maintainer)
        allow(view).to receive(:current_user).and_return(maintainer)
      end

      it 'renders the empty state' do
        render

        expect(rendered).to have_css(
          '#js-project-compliance-framework-empty-state'\
            "[data-empty-state-svg-path]"\
            "[data-group-name=\"#{group.name}\"]"\
            "[data-group-path=\"#{group_path(group)}\"]"
        )
      end

      it 'hides the submit button' do
        expect(rendered).not_to have_button('Save changes')
      end
    end
  end
end
