# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService, feature_category: :compliance_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:branch_name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: branch_name, project: project) }
  let(:user) { project.first_owner }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with invalid params' do
      let(:params) do
        {
          name: branch_name,
          push_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
        }
      end

      it "does not add a security audit event entry" do
        expect { service.execute(protected_branch) }.not_to change(::AuditEvent, :count)
      end
    end

    context 'with valid params' do
      let(:params) do
        {
          name: branch_name,
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }],
          push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }]
        }
      end

      it 'adds security audit event entries' do
        expect { service.execute(protected_branch) }.to change(::AuditEvent, :count).by(2)
      end

      context 'with blocking scan result policy' do
        before do
          project.repository.add_branch(user, protected_branch.name, 'master')
        end

        include_context 'with scan result policy blocking protected branches' do
          let(:policy_configuration) do
            create(:security_orchestration_policy_configuration, project: protected_branch.project)
          end
        end

        it 'blocks unprotecting branches' do
          expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end
end
