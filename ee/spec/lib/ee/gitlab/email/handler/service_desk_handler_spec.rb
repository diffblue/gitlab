# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::ServiceDeskHandler do
  include ServiceDeskHelper
  include_context 'email shared context'

  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { email_fixture('emails/service_desk.eml') }
  let_it_be_with_refind(:group) { create(:group, :private, name: "email") }

  let(:expected_description) do
    "Service desk stuff!\n\n```\na = b\n```\n\n`/label ~label1`\n`/assign @user1`\n`/close`"
  end

  context 'service desk is enabled for the project' do
    let_it_be(:project) { create(:project, :repository, :private, group: group, path: 'test', service_desk_enabled: true) }

    before do
      allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
    end

    context 'when everything is fine' do
      context 'when using issue templates' do
        context 'that are inherited' do
          let_it_be_with_reload(:settings) { create(:service_desk_setting, project: project) }
          let_it_be(:project_with_instance_template) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/inherited_instance_template.md' => 'instance template' }) }

          context 'from instance' do
            before do
              stub_licensed_features(custom_file_templates: true)
              stub_ee_application_setting(file_template_project: project_with_instance_template)
            end

            it 'appends instance issue description template' do
              settings.update!(issue_template_key: 'inherited_instance_template')

              receiver.execute

              issue_description = Issue.last.description
              expect(issue_description).to include(expected_description)
              expect(issue_description.lines.last).to eq('instance template')
            end
          end

          context 'from groups' do
            let_it_be(:project_with_group_template) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/inherited_group_template.md' => 'group template' }) }

            before do
              stub_licensed_features(custom_file_templates_for_namespace: true)
            end

            it 'appends group issue description template' do
              create(:project_group_link, project: project_with_group_template, group: group)
              group.update!(file_template_project_id: project_with_group_template.id)
              settings.update!(issue_template_key: 'inherited_group_template')

              receiver.execute
              issue_description = Issue.last.description
              expect(issue_description).to include(expected_description)
              expect(issue_description.lines.last).to eq('group template')
            end
          end
        end

        context 'that has quick actions' do
          context 'assigning issue to epic' do
            let_it_be(:user) { create(:user) }
            let_it_be(:settings) { create(:service_desk_setting, project: project) }

            before do
              stub_licensed_features(epics: true)
            end

            it 'assigns epic' do
              epic = create(:epic, group: group)
              file_content = "/epic #{epic.to_reference}"
              set_template_file('assign_epic', file_content)

              receiver.execute

              expect(Issue.last.epic).to eq(epic)
            end
          end
        end
      end
    end
  end
end
