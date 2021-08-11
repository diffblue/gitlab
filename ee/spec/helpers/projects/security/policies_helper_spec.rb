# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::PoliciesHelper do
  describe '#assigned_policy_project' do
    let(:project) { create(:project) }

    context 'when a project does have a security policy project' do
      let(:policy_management_project) { create(:project) }

      subject { helper.assigned_policy_project(project) }

      it {
        create(:security_orchestration_policy_configuration,
          { security_policy_management_project: policy_management_project, project: project }
        )

        is_expected.to include({
          id: policy_management_project.to_global_id.to_s,
          name: policy_management_project.name,
          full_path: policy_management_project.full_path,
          branch: policy_management_project.default_branch_or_main
        })
      }
    end

    context 'when a project does not have a security policy project' do
      subject { helper.assigned_policy_project(project) }

      it {
        is_expected.to be_nil
      }
    end
  end
end
