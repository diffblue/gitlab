# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDeskSetting do
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_with_group_template) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/inherited_group_template.md' => 'group template' }) }
  let_it_be(:project_with_instance_template) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/inherited_instance_template.md' => 'instance template' }) }

  before_all do
    create(:project_group_link, project: project_with_group_template, group: group)
  end

  subject { build(:service_desk_setting) }

  describe '.issue_template_content' do
    context 'when file_template_project_id is present' do
      context 'for group templates' do
        before do
          stub_licensed_features(custom_file_templates_for_namespace: true)
          group.update!(file_template_project_id: project_with_group_template.id)
        end

        it 'returns template content' do
          settings =
            build(:service_desk_setting,
              project: project,
              file_template_project_id:
              project_with_group_template.id,
              issue_template_key: 'inherited_group_template'
            )

          expect(settings.issue_template_content).to eq('group template')
        end
      end

      context 'for instance templates' do
        before do
          stub_licensed_features(custom_file_templates: true)
          stub_ee_application_setting(file_template_project: project_with_instance_template)
        end

        it 'returns template content' do
          settings = build(:service_desk_setting, project: project, file_template_project_id: project_with_instance_template.id, issue_template_key: 'inherited_instance_template')

          expect(settings.issue_template_content).to eq('instance template')
        end
      end
    end
  end
end
