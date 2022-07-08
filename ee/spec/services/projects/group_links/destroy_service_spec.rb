# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupLinks::DestroyService do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }
  let!(:project) { create(:project) }
  let!(:group_link) { create(:project_group_link, project: project, group: group) }

  subject { described_class.new(project, user, {}) }

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { subject.execute(group_link) }
      let(:fail_condition!) do
        expect_any_instance_of(ProjectGroupLink)
          .to receive(:destroy).and_return(group_link)
      end

      let(:attributes) do
        {
           author_id: user.id,
           entity_id: group.id,
           entity_type: 'Group',
           details: {
             remove: 'project_access',
             author_name: user.name,
             target_id: project.id,
             target_type: 'Project',
             target_details: project.full_path
           }
         }
      end
    end

    it 'sends the audit streaming event' do
      audit_context = {
        name: 'project_group_link_destroy',
        stream_only: true,
        author: user,
        scope: project,
        target: group,
        message: "Removed project group link"
      }
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)

      subject.execute(group_link)
    end
  end
end
