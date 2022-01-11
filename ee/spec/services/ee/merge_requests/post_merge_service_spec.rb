# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PostMergeService do
  let_it_be(:project) { create(:project, :repository) }
  # Works around https://gitlab.com/gitlab-org/gitlab/-/issues/335054
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:current_user) { merge_request.author }
  let(:service) { described_class.new(project: project, current_user: current_user) }

  subject { service.execute(merge_request) }

  describe '#execute' do
    context 'finalize approvals' do
      let(:finalize_service) { double(:finalize_service) }

      it 'executes ApprovalRules::FinalizeService' do
        expect(ApprovalRules::FinalizeService).to receive(:new).and_return(finalize_service)
        expect(finalize_service).to receive(:execute)

        subject
      end
    end

    context 'compliance violations' do
      shared_examples 'does not call the compliance violations worker' do
        it do
          expect(ComplianceManagement::MergeRequests::ComplianceViolationsWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'when the compliance report feature is unlicensed' do
        before do
          stub_licensed_features(group_level_compliance_dashboard: false)
        end

        it_behaves_like 'does not call the compliance violations worker'
      end

      context 'when the compliance violations graphql type is disabled' do
        before do
          stub_feature_flags(compliance_violations_graphql_type: false)
        end

        it_behaves_like 'does not call the compliance violations worker'
      end

      context 'when the compliance violations graphql type is enabled' do
        before do
          stub_feature_flags(compliance_violations_graphql_type: true)
          stub_licensed_features(group_level_compliance_dashboard: true)
        end

        it 'calls the compliance violations worker asynchronously' do
          expect(ComplianceManagement::MergeRequests::ComplianceViolationsWorker).to receive(:perform_async).with(merge_request.id)

          subject
        end
      end
    end
  end
end
