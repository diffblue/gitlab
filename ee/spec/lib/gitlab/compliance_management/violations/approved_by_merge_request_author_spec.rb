# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ComplianceManagement::Violations::ApprovedByMergeRequestAuthor,
feature_category: :compliance_management do
  let_it_be(:author) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, state: :merged, author: author) }

  subject(:violation) { described_class.new(merge_request) }

  describe '#execute' do
    shared_examples 'violation' do
      it 'creates a ComplianceViolation', :aggregate_failures do
        expect { execute }.to change { merge_request.compliance_violations.count }.by(1)

        violations = merge_request.compliance_violations.where(reason: described_class::REASON)

        expect(violations.map(&:violating_user)).to contain_exactly(author)
        expect(violations.map(&:severity_level)).to contain_exactly('high')
        expect(violations.map(&:target_project_id)).to contain_exactly(merge_request.target_project_id)
        expect(violations.map(&:title)).to contain_exactly(merge_request.title)
        expect(violations.map(&:target_branch)).to contain_exactly(merge_request.target_branch)
      end
    end

    subject(:execute) { violation.execute }

    context 'when merge request is approved by someone other than the author' do
      before do
        create(:approval, merge_request: merge_request)
      end

      it 'does not create a ComplianceViolation' do
        expect { execute }.not_to change(MergeRequests::ComplianceViolation, :count)
      end

      context 'when merge request is also approved by the author' do
        before do
          create(:approval, merge_request: merge_request, user: author)
        end

        it_behaves_like 'violation'
      end
    end

    context 'when merge request is approved by its author' do
      before do
        create(:approval, merge_request: merge_request, user: author)
      end

      it_behaves_like 'violation'
    end
  end
end
