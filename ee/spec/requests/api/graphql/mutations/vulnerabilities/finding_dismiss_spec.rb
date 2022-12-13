# frozen_string_literal: true

require 'spec_helper'
RSpec.describe 'Dismissing a Vulnerabilities::Finding object', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:finding) { create(:vulnerabilities_finding, :with_pipeline, project: project, severity: :high) }

  let(:params) do
    {
      id: finding.to_global_id.to_s
    }
  end

  let(:mutation) do
    graphql_mutation(
      :vulnerability_finding_dismiss,
      params
    )
  end

  let(:mutation_response) do
    graphql_mutation_response(:vulnerability_finding_dismiss)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not dismiss the Finding' do
      expect { subject }.not_to change(finding, :state)
    end
  end

  context 'when the user has permission' do
    before do
      finding.project.add_developer(current_user)
    end

    context 'when security_dashboard is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when security_dashboard is enabled' do
      before do
        stub_licensed_features(security_dashboard: true)
        stub_feature_flags(deprecate_vulnerabilities_feedback: false)
      end

      it 'dismisses the Finding' do
        expect { subject }.to change(finding, :state).from('detected').to('dismissed')
      end

      context 'when comment is given' do
        let(:comment) { "Used in tests" }
        let(:params) do
          {
            id: finding.to_global_id.to_s,
            comment: comment
          }
        end

        let(:feedback) { finding.dismissal_feedback }

        it 'saves the comment' do
          expect { subject }.to change(finding, :state).from('detected').to('dismissed')
          expect(feedback.comment).to eq(comment)
        end
      end

      context 'when dismissal reason is given' do
        let(:dismissal_reason) { "USED_IN_TESTS" }
        let(:params) do
          {
            id: finding.to_global_id.to_s,
            dismissal_reason: dismissal_reason
          }
        end

        let(:feedback) { finding.dismissal_feedback }

        it 'saves the dismissal reason' do
          expect { subject }.to change(finding, :state).from('detected').to('dismissed')
          expect(feedback.dismissal_reason).to eq('used_in_tests')
        end
      end
    end
  end
end
