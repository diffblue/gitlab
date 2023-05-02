# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Ci::JobTokenScope::AddProject, feature_category: :continuous_integration do
  let(:mutation) do
    described_class.new(object: nil, context: { current_user: current_user }, field: nil)
  end

  describe '#resolve' do
    let_it_be(:project) do
      create(:project, ci_outbound_job_token_scope_enabled: true)
    end

    let_it_be(:target_project) { create(:project) }

    let(:target_project_path) { target_project.full_path }
    let(:project_path) { project.full_path }
    let(:mutation_args) do
      {
        project_path: project.full_path,
        target_project_path: target_project_path,
        direction: :inbound
      }
    end

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

    context 'when user adds target project to the inbound job token scope' do
      let(:expected_audit_message) do
        "Project #{target_project_path} was added to inbound list of allowed projects for #{project_path}"
      end

      let(:event_name) { 'secure_ci_job_token_project_added' }

      it 'logs an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(expected_audit_context))

        subject
      end

      context 'and service returns an error' do
        it 'does not log an audit event' do
          expect_next_instance_of(::Ci::JobTokenScope::AddProjectService) do |service|
            expect(service)
              .to receive(:validate_edit!)
            .with(project, target_project, current_user)
            .and_raise(ActiveRecord::RecordNotUnique)
          end

          expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

          subject
        end
      end
    end

    context 'when user adds target project to the outbound job token scope' do
      let(:mutation_args) do
        { project_path: project.full_path,
          target_project_path: target_project_path,
          direction: :outbound }
      end

      it 'does not log an audit event' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        subject
      end
    end
  end
end
