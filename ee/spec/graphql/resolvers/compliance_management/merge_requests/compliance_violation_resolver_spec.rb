# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ComplianceManagement::MergeRequests::ComplianceViolationResolver do
  include GraphqlHelpers

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

  describe '#resolve' do
    subject(:resolve_compliance_violations) { resolve(described_class, obj: group, ctx: { current_user: current_user }) }

    context 'feature flag is disabled' do
      before do
        stub_feature_flags(compliance_violations_graphql_type: false)
      end

      it 'returns an empty collection' do
        expect(subject).to be_empty
      end
    end

    context 'feature flag is enabled' do
      context 'user is unauthorized' do
        it 'returns an empty collection' do
          expect(subject).to be_empty
        end
      end

      context 'user is authorized' do
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
