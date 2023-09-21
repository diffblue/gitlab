# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ProtectedEnvironments::UpdateService, '#execute', feature_category: :environment_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:maintainer_access) { Gitlab::Access::MAINTAINER }
  let(:protected_environment) { create(:protected_environment, project: project) }
  let(:deploy_access_level) { protected_environment.deploy_access_levels.first }

  let(:params) do
    {
      deploy_access_levels_attributes: [
        { id: deploy_access_level.id, access_level: Gitlab::Access::DEVELOPER, user_id: nil },
        { access_level: maintainer_access }
      ]
    }
  end

  subject { described_class.new(container: project, current_user: user, params: params).execute(protected_environment) }

  before do
    deploy_access_level
  end

  context 'with valid params' do
    it { is_expected.to be_truthy }

    it 'updates the deploy access levels' do
      expect do
        subject
      end.to change { ProtectedEnvironments::DeployAccessLevel.count }.from(1).to(2)
    end
  end

  context 'with invalid params' do
    let(:maintainer_access) { 0 }

    it { is_expected.to be_falsy }

    it 'does not update the deploy access levels' do
      expect do
        subject
      end.not_to change { ProtectedEnvironments::DeployAccessLevel.count }
    end

    context 'multiple deploy access levels' do
      let(:params) do
        attributes_for(:protected_environment,
                       deploy_access_levels_attributes: [{ group_id: group.id, user_id: user_to_add.id }])
      end

      it_behaves_like 'invalid multiple deployment access levels'
    end
  end

  context 'deploy access level by group' do
    let(:params) { { deploy_access_levels_attributes: [{ group_id: group.id }] } }

    it_behaves_like 'invalid protected environment group'

    it_behaves_like 'valid protected environment group'
  end

  context 'deploy access level by user' do
    let(:params) do
      attributes_for(:protected_environment,
                     deploy_access_levels_attributes: [{ user_id: user_to_add.id }])
    end

    it_behaves_like 'invalid protected environment user'

    it_behaves_like 'valid protected environment user'
  end

  describe 'auditing changes' do
    before do
      project.project_group_links.create!(
        group_id: invited_group.id,
        group_access: Gitlab::Access::DEVELOPER,
        expires_at: 1.month.from_now
      )

      allow(::Gitlab::Audit::Auditor).to receive(:audit)
    end

    let(:admin_user) { create(:user, :admin) }

    let(:invited_group) { create(:group) }
    let(:project_user) { project.users.first }

    let(:protected_environment) do
      create(
        :protected_environment,
        :maintainers_can_deploy,
        :maintainers_can_approve,
        authorize_user_to_deploy: admin_user,
        require_users_to_approve: [admin_user, project_user],
        name: 'staging',
        required_approval_count: 1,
        project: project
      )
    end

    let(:deploy_access_levels) { protected_environment.deploy_access_levels }
    let(:deploy_access_for_delete) { find_authorization_rule(deploy_access_levels, :user_id, admin_user.id) }
    let(:deploy_access_for_update) do
      find_authorization_rule(deploy_access_levels, :access_level, Gitlab::Access::MAINTAINER)
    end

    let(:approval_rules) { protected_environment.approval_rules }
    let(:approval_rule_for_delete) { find_authorization_rule(approval_rules, :user_id, admin_user.id) }
    let(:approval_rule_for_update_1) { find_authorization_rule(approval_rules, :user_id, project_user.id) }
    let(:approval_rule_for_update_2) do
      find_authorization_rule(approval_rules, :access_level, Gitlab::Access::MAINTAINER)
    end

    let(:params) do
      {
        required_approval_count: 3,
        deploy_access_levels_attributes: [
          { id: deploy_access_for_delete.id, _destroy: true },
          { id: deploy_access_for_update.id, access_level: nil, user_id: project_user.id },
          { access_level: Gitlab::Access::DEVELOPER }
        ],
        approval_rules_attributes: [
          { id: approval_rule_for_delete.id, _destroy: true },
          {
            id: approval_rule_for_update_1.id,
            access_level: nil, user_id: nil,
            group_id: invited_group.id,
            required_approvals: 5
          },
          { id: approval_rule_for_update_2.id, required_approvals: 4 },
          { access_level: Gitlab::Access::DEVELOPER, required_approvals: 1 }
        ]
      }
    end

    it 'stores and logs the audit event for the protected_environment update' do
      subject

      expected_audit_context = {
        name: 'protected_environment_updated',
        author: user,
        scope: project,
        target: protected_environment.reload,
        message: "Changed required_approval_count from 1 to 3",
        target_details: nil,
        additional_details: {
          change: :required_approval_count,
          from: 1,
          to: 3
        }
      }

      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(expected_audit_context)
    end

    it 'stores and logs the audit events for the changes in deploy_access_levels', :aggregate_failures do
      subject

      expected_audit_context = {
        author: user,
        scope: project,
        target: protected_environment.reload
      }

      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_deploy_access_level_deleted',
          message: "Deleted deploy access level #{deploy_access_for_delete.humanize}."
        )
      )
      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_deploy_access_level_updated',
          message: "Changed deploy access level " \
                   "from #{humanize_access_level(Gitlab::Access::MAINTAINER)} " \
                   "to user with ID #{project_user.id}."
        )
      )
      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_deploy_access_level_added',
          message: "Added deploy access level #{humanize_access_level(Gitlab::Access::DEVELOPER)}."
        )
      )
    end

    it 'stores and logs the audit events for the changes in approval_rules' do
      subject

      expected_audit_context = {
        author: user,
        scope: project,
        target: protected_environment.reload
      }

      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_approval_rule_deleted',
          message: "Deleted approval rule for #{approval_rule_for_delete.humanize}."
        )
      )
      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_approval_rule_updated',
          message: "Updated approval rule for user with ID #{project_user.id} " \
                   "with required approval count 1 " \
                   "to group with ID #{invited_group.id} with required approval count 5."
        )
      )
      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_approval_rule_updated',
          message: "Updated approval rule for #{humanize_access_level(Gitlab::Access::MAINTAINER)} " \
                   "with required approval count from 1 to 4."
        )
      )
      expect(::Gitlab::Audit::Auditor).to have_received(:audit).with(
        expected_audit_context.merge(
          name: 'protected_environment_approval_rule_added',
          message: "Added approval rule for #{humanize_access_level(Gitlab::Access::DEVELOPER)} " \
                   "with required approval count 1."
        )
      )
    end

    context 'when there are updates to non-auditable attributes only' do
      let(:params) do
        {
          deploy_access_levels_attributes: [
            { id: deploy_access_for_update.id, group_inheritance_type: 1 }
          ],
          approval_rules_attributes: [
            { id: approval_rule_for_update_2.id, group_inheritance_type: 1 }
          ]
        }
      end

      it 'does not log any audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_updated'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_deploy_access_level_added'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_deploy_access_level_updated'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_deploy_access_level_deleted'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_approval_rule_added'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_approval_rule_updated'
        )
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit).with(
          name: 'protected_environment_approval_rule_deleted'
        )

        subject
      end
    end
  end

  def humanize_access_level(access_level)
    ::ProtectedEnvironments::DeployAccessLevel::HUMAN_ACCESS_LEVELS[access_level]
  end

  def find_authorization_rule(authorization_rules, attr_name, attr_value)
    authorization_rules.detect { |ar| ar.send(attr_name) == attr_value }
  end
end
