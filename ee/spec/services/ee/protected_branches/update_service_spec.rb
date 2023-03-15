# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService, feature_category: :compliance_management do
  let(:branch_name) { 'feature' }
  let(:protected_branch) { create(:protected_branch, name: branch_name) }
  let(:project) { protected_branch.project }
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
    end
  end
end
