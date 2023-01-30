# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ComplianceManagement::Violations::ApprovedByCommitter,
feature_category: :compliance_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:user3) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, state: :merged) }

  subject(:violation) { described_class.new(merge_request) }

  describe '#execute' do
    before do
      allow(merge_request).to receive(:committers).and_return([user, user2])
    end

    subject(:execute) { violation.execute }

    context 'when merge request is approved by someone who did not add a commit' do
      it 'does not create a ComplianceViolation' do
        expect { execute }.not_to change(MergeRequests::ComplianceViolation, :count)
      end
    end

    context 'when merge request is approved by someone who also added a commit' do
      let_it_be(:merge_request) { create(:merge_request, state: :merged) }

      before do
        create(:approval, merge_request: merge_request, user: user)
        create(:approval, merge_request: merge_request, user: user2)
        create(:approval, merge_request: merge_request, user: user3)
      end

      it 'creates a ComplianceViolation for each violation', :aggregate_failures do
        expect { execute }.to change { merge_request.compliance_violations.count }.by(2)

        violations = merge_request.compliance_violations.where(reason: described_class::REASON)
        target_project_id = merge_request.target_project_id
        target_branch = merge_request.target_branch

        expect(violations.map(&:violating_user)).to contain_exactly(user, user2)
        expect(violations.map(&:severity_level)).to contain_exactly('high', 'high')
        expect(violations.map(&:target_project_id)).to contain_exactly(target_project_id, target_project_id)
        expect(violations.map(&:title)).to contain_exactly(merge_request.title, merge_request.title)
        expect(violations.map(&:target_branch)).to contain_exactly(target_branch, target_branch)
      end

      context 'when called more than once with the same violations' do
        before do
          create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user)
          create(:compliance_violation, :approved_by_committer, merge_request: merge_request, violating_user: user2)

          allow(merge_request).to receive(:committers).and_return([user, user3])
        end

        it 'does not insert duplicates', :aggregate_failures do
          expect { execute }.to change { merge_request.compliance_violations.count }.by(1)

          violations = merge_request.compliance_violations.where(reason: described_class::REASON)

          expect(violations.map(&:violating_user)).to contain_exactly(user, user2, user3)
          expect(violations.map(&:severity_level)).to contain_exactly('high', 'high', 'high')
        end
      end
    end
  end
end
