# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::DestroyService do
  let(:protected_branch) { create(:protected_branch) }
  let(:branch_name) { protected_branch.name }
  let(:project) { protected_branch.project }
  let(:user) { project.first_owner }

  describe '#execute' do
    subject(:service) { described_class.new(project, user) }

    it 'adds a security audit event entry' do
      expect { service.execute(protected_branch) }.to change(::AuditEvent, :count).by(1)
    end

    context 'when destroy fails' do
      before do
        expect(protected_branch).to receive(:destroy).and_return(false)
      end

      it "doesn't add a security audit event entry" do
        expect { service.execute(protected_branch) }.not_to change(::AuditEvent, :count)
      end
    end
  end
end
