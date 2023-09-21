# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProtectedEnvironmentAuthorizationRuleChangesAuditor, '#audit', feature_category: :environment_management do
  let_it_be(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:invited_group) { create(:group) }
  let(:project_user) { project.users.first }
  let(:admin_user) { create(:user, :admin) }

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

  before do
    project.project_group_links.create!(
      group_id: invited_group.id,
      group_access: Gitlab::Access::DEVELOPER,
      expires_at: 1.month.from_now
    )

    allow(::Gitlab::Audit::Auditor).to receive(:audit)
  end

  subject do
    protected_environment.update!(params)

    described_class.new(
      author: user,
      scope: project,
      protected_environment: protected_environment,
      deleted_deploy_access_levels: [deploy_access_for_delete],
      deleted_approval_rules: [approval_rule_for_delete]
    ).audit
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

  it 'stores and logs the audit events for the changes in approval_rules', :aggregate_failures do
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

  def humanize_access_level(access_level)
    ::ProtectedEnvironments::DeployAccessLevel::HUMAN_ACCESS_LEVELS[access_level]
  end

  def find_authorization_rule(authorization_rules, attr_name, attr_value)
    authorization_rules.detect { |ar| ar.send(attr_name) == attr_value }
  end
end
