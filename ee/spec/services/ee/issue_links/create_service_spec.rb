# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let(:namespace) { create :namespace }
    let(:project) { create :project, namespace: namespace }
    let(:issue) { create :issue, project: project }
    let(:user) { create :user }
    let(:params) do
      {}
    end

    before do
      stub_licensed_features(blocked_issues: true)

      project.add_developer(user)
    end

    subject { described_class.new(issue, user, params).execute }

    context 'when there is an issue to relate' do
      let(:issue_a) { create :issue, project: project }
      let(:another_project) { create :project, namespace: project.namespace }
      let(:another_project_issue) { create :issue, project: another_project }

      let(:issue_a_ref) { issue_a.to_reference }
      let(:another_project_issue_ref) { another_project_issue.to_reference(project) }

      let(:params) do
        { issuable_references: [issue_a_ref, another_project_issue_ref], link_type: 'blocks' }
      end

      before do
        another_project.add_developer(user)
      end

      context 'when feature is not available' do
        before do
          stub_licensed_features(blocked_issues: false)
        end

        it 'returns error' do
          is_expected.to eq(message: 'Blocked issues not available for current license', status: :error, http_status: 403)
        end

        it 'no relationship is created' do
          expect { subject }.not_to change(IssueLink, :count)
        end
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references]).not_to be_empty
      end

      it_behaves_like 'issuable link creation with blocking link_type' do
        let(:issuable_link_class) { IssueLink }
        let(:issuable) { issue }
        let(:issuable2) { issue_a }
        let(:issuable3) { another_project_issue }
      end
    end

    context 'when reference of any already related issue is present' do
      let(:issue_a) { create :issue, project: project }
      let(:issue_b) { create :issue, project: project }
      let(:issue_c) { create :issue, project: project }

      before do
        create :issue_link, source: issue, target: issue_b, link_type: IssueLink::TYPE_RELATES_TO
        create :issue_link, source: issue, target: issue_c, link_type: IssueLink::TYPE_BLOCKS
      end

      let(:params) do
        {
          issuable_references: [
            issue_a.to_reference,
            issue_b.to_reference,
            issue_c.to_reference
          ],
          link_type: IssueLink::TYPE_BLOCKS
        }
      end

      it 'sets the same type of relation for selected references' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].count).to eq(3)
        expect(IssueLink.where(target: [issue_a, issue_b, issue_c]).pluck(:link_type))
          .to eq([IssueLink::TYPE_BLOCKS, IssueLink::TYPE_BLOCKS, IssueLink::TYPE_BLOCKS])
      end
    end
  end
end
