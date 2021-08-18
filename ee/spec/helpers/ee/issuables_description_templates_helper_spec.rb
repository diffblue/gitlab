# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesDescriptionTemplatesHelper do
  include_context 'project issuable templates context'

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:parent_group) { create(:group) }
  let_it_be_with_reload(:group) { create(:group, parent: parent_group) }
  let_it_be_with_reload(:project) { create(:project, :custom_repo, group: group, files: issuable_template_files) }
  let_it_be(:file_template_project) { create(:project, :custom_repo, group: parent_group, files: issuable_template_files) }
  let_it_be(:group_member) { create(:group_member, :developer, group: parent_group, user: user) }
  let_it_be(:inherited_from) { file_template_project }

  shared_examples 'issuable templates' do
    context 'when include_inherited_templates is true' do
      it 'returns project templates and inherited templates' do
        expect(helper.issuable_templates_names(Issue.new, true)).to eq(%w[project_template inherited_template])
      end
    end

    context 'when include_inherited_templates is false' do
      it 'returns only project templates' do
        expect(helper.issuable_templates_names(Issue.new)).to eq(%w[project_template])
      end
    end
  end

  describe '#issuable_templates' do
    context 'when project parent group has a file template project' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        parent_group.update_columns(file_template_project_id: file_template_project.id)
      end

      it_behaves_like 'project issuable templates'
    end
  end

  describe '#issuable_template_names' do
    let(:templates) do
      {
        '' => [{ name: 'project_template', id: 'project_issue_template', project_id: project.id }],
        'Instance' => [{ name: 'inherited_template', id: 'instance_issue_template', project_id: file_template_project.id }]
      }
    end

    before do
      allow(helper).to receive(:ref_project).and_return(project)
      allow(helper).to receive(:issuable_templates).and_return(templates)
    end

    it_behaves_like 'issuable templates'
  end
end
