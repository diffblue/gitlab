# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::RevokeService, feature_category: :deployment_management do
  describe '#execute' do
    let(:agent) { create(:cluster_agent) }
    let(:agent_token) { create(:cluster_agent_token, agent: agent) }
    let(:project) { agent.project }
    let(:user) { agent.created_by_user }

    before do
      project.add_maintainer(user)
    end

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when user revokes agent token' do
        it 'creates AuditEvent with success message' do
          expect_to_audit(
            user,
            project,
            agent,
            "Revoked cluster agent token '#{agent_token.name}' with id #{agent_token.id}"
          )

          described_class.new(token: agent_token, current_user: user).execute
        end
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user) }

      before do
        project.add_guest(unauthorized_user)
      end

      context 'when user attempts to revoke agent token' do
        it 'creates audit logs with failure message' do
          expect_to_audit(
            unauthorized_user,
            project,
            agent,
            "Attempted to revoke cluster agent token '#{agent_token.name}' with " \
            "id #{agent_token.id} but failed with message: " \
            "User has insufficient permissions to revoke the token for this project"
          )

          described_class.new(token: agent_token, current_user: unauthorized_user).execute
        end
      end
    end
  end

  def expect_to_audit(current_user, scope, target, message)
    audit_context = {
      name: 'cluster_agent_token_revoked',
      author: current_user,
      scope: scope,
      target: target,
      message: message
    }

    expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
      .and_call_original
  end
end
