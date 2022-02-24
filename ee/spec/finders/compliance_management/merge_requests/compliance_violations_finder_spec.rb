# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::ComplianceViolationsFinder do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged) }
  let_it_be(:merge_request2) { create(:merge_request, source_project: project2, target_project: project2, state: :merged) }
  let_it_be(:merge_request_outside_group) { create(:merge_request, source_project: project_outside_group, target_project: project_outside_group, state: :merged) }
  let_it_be(:compliance_violation) { create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request) }
  let_it_be(:compliance_violation2) { create(:compliance_violation, :approved_by_merge_request_author, severity_level: :high, merge_request: merge_request2) }
  let_it_be(:compliance_violation_outside_group) { create(:compliance_violation, :approved_by_committer, merge_request: merge_request_outside_group) }

  subject(:finder) { described_class.new(current_user: current_user, group: group) }

  describe '#execute' do
    subject { finder.execute }

    context 'when feature is disabled' do
      before do
        stub_feature_flags(compliance_violations_graphql_type: false)
      end

      it 'returns no compliance violations' do
        expect(subject).to eq(::MergeRequests::ComplianceViolation.none)
      end
    end

    context 'when feature is enabled' do
      before do
        stub_feature_flags(compliance_violations_graphql_type: true)
      end

      context 'when the user is unauthorized' do
        it 'returns no compliance violations' do
          expect(subject).to eq(::MergeRequests::ComplianceViolation.none)
        end
      end

      context 'when the user is authorized' do
        before do
          group.add_owner(current_user)
        end

        context 'without any filters or sorting' do
          it 'finds all the compliance violations' do
            expect(subject).to contain_exactly(compliance_violation, compliance_violation2)
          end
        end
      end
    end
  end
end
