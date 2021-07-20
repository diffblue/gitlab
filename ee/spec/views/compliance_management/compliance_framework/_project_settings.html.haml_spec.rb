# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'compliance_management/compliance_framework/_project_settings.html.haml' do
  let_it_be(:group) { create(:group) }
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:project) { create(:project, namespace: group) }

  before do
    allow(view).to receive(:current_user).and_return(group_owner)
    allow(view).to receive(:expanded).and_return(true)
    allow(group_owner).to receive(:can?).and_return(true)
    assign(:project, project)
    stub_licensed_features(custom_compliance_frameworks: true)
  end

  it 'shows the section description' do
    render

    expect(rendered).to have_text 'Select a framework that applies to this project. How are these added?'
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

        expect(rendered).to have_text('Customizable by owners.')
      end

      it 'disables the dropdown' do
        render

        expect(rendered).to have_css('input[id=project_compliance_framework_setting_attributes_framework][disabled="disabled"]')
      end

      it 'hides the submit button' do
        expect(rendered).not_to have_button('Save changes')
      end
    end
  end

  context 'group has no compliance frameworks' do
    before do
      group.compliance_management_frameworks.delete_all
    end

    it 'shows the empty text' do
      render

      expect(rendered).to match /No compliance frameworks are in use. Create one from the .* section in Group Settings./
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

      it 'shows the empty text' do
        render

        expect(rendered).to have_text('No compliance frameworks are in use.')
      end

      it 'hides the submit button' do
        expect(rendered).not_to have_button('Save changes')
      end
    end
  end
end
