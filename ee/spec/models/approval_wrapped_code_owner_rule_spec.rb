# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalWrappedCodeOwnerRule do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:merge_request) { create(:merge_request) }

  subject { described_class.new(merge_request, rule) }

  describe '#approvals_required' do
    where(:feature_enabled, :optional_section, :approver_count, :approvals_required, :expected_required_approvals) do
      true  | false | 0 | 0 | 0
      true  | false | 2 | 0 | 1
      true  | true  | 2 | 0 | 0
      true  | false | 0 | 2 | 0
      true  | false | 2 | 2 | 2
      false | false | 2 | 0 | 0
      false | false | 0 | 0 | 0
    end

    with_them do
      let(:rule) do
        create(:code_owner_rule,
                merge_request: merge_request,
                users: create_list(:user, approver_count),
                approvals_required: approvals_required)
      end

      let(:branch) { subject.project.repository.branches.find { |b| b.name == merge_request.target_branch } }

      context "when project.code_owner_approval_required_available? is true" do
        before do
          allow(subject.project)
            .to receive(:code_owner_approval_required_available?).and_return(true)
          allow(Gitlab::CodeOwners).to receive(:optional_section?).and_return(optional_section)
        end

        context "when the project doesn't require code owner approval on all MRs" do
          it 'returns the expected number of approvals for protected_branches that do require approval' do
            allow(subject.project)
              .to receive(:merge_requests_require_code_owner_approval?).and_return(false)
            allow(ProtectedBranch)
              .to receive(:branch_requires_code_owner_approval?).with(subject.project, branch.name).and_return(feature_enabled)

            expect(subject.approvals_required).to eq(expected_required_approvals)
          end
        end
      end

      context "when project.code_owner_approval_required_available? is falsy" do
        it "returns nil" do
          allow(subject.project)
            .to receive(:code_owner_approval_required_available?).and_return(false)

          expect(subject.approvals_required).to eq(0)
        end
      end
    end
  end
end
