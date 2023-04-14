# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::MergeRequests::ComplianceViolationsFinder, feature_category: :compliance_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:project2) { create(:project, :repository, group: group) }
  let_it_be(:project_outside_group) { create(:project, :repository, group: create(:group)) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project, state: :merged, title: 'abcd', target_branch: 'dev') }
  let_it_be(:merge_request2) { create(:merge_request, source_project: project2, target_project: project2, state: :merged, title: 'zyxw', target_branch: 'stable') }
  let_it_be(:merge_request_outside_group) { create(:merge_request, source_project: project_outside_group, target_project: project_outside_group, state: :merged) }
  let_it_be(:compliance_violation) do
    create(:compliance_violation, :approved_by_committer, severity_level: :low, merge_request: merge_request,
      title: 'abcd', target_project_id: project.id, target_branch: merge_request.target_branch, merged_at: 3.days.ago)
  end

  let_it_be(:compliance_violation2) do
    create(:compliance_violation, :approved_by_merge_request_author, severity_level: :high,
      merge_request: merge_request2, title: 'zyxw', target_project_id: project2.id,
      target_branch: merge_request2.target_branch, merged_at: 1.day.ago)
  end

  let_it_be(:compliance_violation_outside_group) do
    create(:compliance_violation, :approved_by_committer, merge_request: merge_request_outside_group,
      title: merge_request_outside_group.title, target_project_id: project_outside_group.id,
      target_branch: merge_request_outside_group.target_branch)
  end

  let(:params) { {} }

  before do
    merge_request.metrics.update!(merged_at: 3.days.ago)
    merge_request2.metrics.update!(merged_at: 1.day.ago)
  end

  subject(:finder) { described_class.new(current_user: current_user, group: group, params: params) }

  describe '#execute' do
    subject { finder.execute }

    context 'when the user is unauthorized' do
      it 'returns nil' do
        expect(subject).to be_nil
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

      context 'filtering the results' do
        context 'when given an array of project IDs' do
          let(:params) { { project_ids: [project.id] } }

          it 'finds the filtered compliance violations' do
            expect(subject).to contain_exactly(compliance_violation)
          end
        end

        context 'when given merged at dates' do
          where(:merged_params, :result) do
            { merged_before: 2.days.ago } | lazy { compliance_violation }
            { merged_after: 2.days.ago } | lazy { compliance_violation2 }
            { merged_before: Date.current, merged_after: 2.days.ago } | lazy { compliance_violation2 }
          end

          with_them do
            let(:params) { merged_params }

            it 'finds the filtered compliance violations' do
              expect(subject).to contain_exactly(result)
            end
          end
        end

        context 'when given a target branch' do
          let(:params) { { target_branch: merge_request.target_branch } }

          it 'finds the filtered compliance violations' do
            expect(subject).to contain_exactly(compliance_violation)
          end
        end
      end

      context 'sorting the results' do
        where(:direction, :result) do
          'SEVERITY_LEVEL_ASC' | lazy { [compliance_violation, compliance_violation2] }
          'SEVERITY_LEVEL_DESC' | lazy { [compliance_violation2, compliance_violation] }
          'VIOLATION_REASON_ASC' | lazy { [compliance_violation, compliance_violation2] }
          'VIOLATION_REASON_DESC' | lazy { [compliance_violation2, compliance_violation] }
          'MERGE_REQUEST_TITLE_ASC' | lazy { [compliance_violation, compliance_violation2] }
          'MERGE_REQUEST_TITLE_DESC' | lazy { [compliance_violation2, compliance_violation] }
          'MERGED_AT_ASC' | lazy { [compliance_violation, compliance_violation2] }
          'MERGED_AT_DESC' | lazy { [compliance_violation2, compliance_violation] }
          'UNKNOWN_SORT' | lazy { [compliance_violation, compliance_violation2] }
        end

        with_them do
          let(:params) { { sort: direction } }

          it 'finds the filtered compliance violations' do
            expect(subject).to match_array(result)
          end
        end
      end
    end
  end
end
