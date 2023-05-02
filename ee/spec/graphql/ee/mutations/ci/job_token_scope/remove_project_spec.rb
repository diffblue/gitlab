# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::RemoveProject, feature_category: :continuous_integration do
  let(:mutation) do
    described_class.new(object: nil, context: { current_user: current_user }, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) do
      create(:project, ci_outbound_job_token_scope_enabled: true)
    end

    let_it_be(:target_project) { create(:project) }

    let_it_be(:link) do
      create(:ci_job_token_project_scope_link,
        direction: :inbound,
        source_project: project,
        target_project: target_project)
    end

    let(:links_relation) { Ci::JobToken::ProjectScopeLink.with_source(project).with_target(target_project) }

    let(:target_project_path) { target_project.full_path }
    let(:project_path) { project.full_path }
    let(:mutation_args) { { project_path: project.full_path, target_project_path: target_project_path } }
    let(:current_user) { create(:user) }

    let(:expected_audit_context) do
      {
        name: event_name,
        author: current_user,
        scope: project,
        target: target_project,
        message: expected_audit_message
      }
    end

    subject do
      mutation.resolve(**mutation_args)
    end

    before do
      project.add_maintainer(current_user)
      target_project.add_guest(current_user)
    end

    context 'when user removes target project to the inbound job token scope' do
      let(:expected_audit_message) do
        "Project #{target_project_path} was removed from inbound list of allowed projects for #{project_path}"
      end

      let(:event_name) { 'secure_ci_job_token_project_removed' }
      let(:mutation_args) do
        { project_path: project.full_path, target_project_path: target_project_path, direction: :inbound }
      end

      let(:service) do
        instance_double('Ci::JobTokenScope::RemoveProjectService')
      end

      it 'logs an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(expected_audit_context))

        subject
      end

      context 'and service returns an error' do
        it 'does not log an audit event' do
          expect(::Ci::JobTokenScope::RemoveProjectService).to receive(:new).with(
            project,
            current_user
          ).and_return(service)
          expect(service)
            .to receive(:execute)
            .with(target_project, :inbound)
            .and_return(ServiceResponse.error(message: 'The error message'))

          expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

          subject
        end
      end
    end

    context 'when user removes target project to the default outbound job token scope' do
      it 'does not log an audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        subject
      end
    end
  end
end
