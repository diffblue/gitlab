# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokens::CreateService, feature_category: :deployment_management do
  describe '#execute' do
    let_it_be(:agent) { create(:cluster_agent) }

    let(:user) { agent.created_by_user }
    let(:project) { agent.project }
    let(:params) { { name: 'some-token', description: 'Test Agent Token', agent_id: agent.id } }

    context 'when user is authorized' do
      before do
        project.add_maintainer(user)
      end

      context 'when user creates agent token' do
        it 'creates AuditEvent with success message' do
          expect_to_audit(
            user,
            project,
            agent,
            /Created cluster agent token 'some-token' with id \d+/
          )

          described_class.new(agent: agent, current_user: user, params: params).execute
        end
      end
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user) }

      before do
        project.add_guest(unauthorized_user)
      end

      context 'when user attempts to create agent token' do
        it 'creates audit logs with failure message' do
          expect_to_audit(
            unauthorized_user,
            project,
            agent,
            "Attempted to create cluster agent token 'some-token' but failed with message: " \
            'User has insufficient permissions to create a token for this project'
          )

          described_class.new(agent: agent, current_user: unauthorized_user, params: params).execute
        end
      end
    end
  end

  def expect_to_audit(current_user, scope, target, message)
    audit_context = {
      name: 'cluster_agent_token_created',
      author: current_user,
      scope: scope,
      target: target,
      message: message
    }

    expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
      .and_call_original
  end
end
