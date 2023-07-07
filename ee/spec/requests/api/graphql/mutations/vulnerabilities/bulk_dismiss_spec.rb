# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Mutation.vulnerabilitiesDismiss", feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:vulnerability_1) { create(:vulnerability, :with_findings, project: project) }
  let_it_be(:vulnerability_2) { create(:vulnerability, :with_findings, project: project) }

  let(:vulnerabilities) { [vulnerability_1, vulnerability_2] }
  let(:vulnerability_ids) { vulnerabilities.map { |v| v.to_global_id.to_s } }
  let(:comment) { 'Dismissal Feedback' }
  let(:dismissal_reason) { 'USED_IN_TESTS' }
  let(:arguments) do
    {
      vulnerability_ids: vulnerability_ids,
      comment: comment,
      dismissal_reason: dismissal_reason
    }
  end

  subject(:mutation) { graphql_mutation(:vulnerabilities_dismiss, arguments) }

  def mutation_response
    graphql_mutation_response(:vulnerabilities_dismiss)
  end

  context "when the user does not have access" do
    it_behaves_like "a mutation that returns a top-level access error"
  end

  context "when the user has access" do
    before_all do
      project.add_developer(current_user)
    end

    context "when security_dashboard is disabled" do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not ' \
                 'exist or you don\'t have permission to perform this action']
    end

    context "when security_dashboard is enabled" do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it "dismisses the vulnerabilities" do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(vulnerability_1.reload).to be_dismissed
        expect(vulnerability_2.reload).to be_dismissed
        expect(mutation_response["errors"]).to be_empty
        expect(mutation_response["vulnerabilities"].count).to eq(2)
        mutation_response["vulnerabilities"].each do |vulnerability|
          expect(vulnerability["state"]).to eq("DISMISSED")
          expect(vulnerability["stateComment"]).to eq(comment)
          expect(vulnerability["dismissedBy"]["id"]).to eq(current_user.to_global_id.to_s)
        end
      end

      context "without a comment" do
        let(:arguments) do
          {
            vulnerability_ids: vulnerability_ids,
            dismissal_reason: dismissal_reason
          }
        end

        it "dismisses the vulnerabilities" do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(vulnerability_1.reload).to be_dismissed
          expect(vulnerability_2.reload).to be_dismissed
          expect(mutation_response["errors"]).to be_empty
        end
      end

      context "without a dismissal reason" do
        let(:arguments) do
          {
            vulnerability_ids: vulnerability_ids,
            comment: comment
          }
        end

        it "dismisses the vulnerabilities" do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(vulnerability_1.reload).to be_dismissed
          expect(vulnerability_2.reload).to be_dismissed
          expect(mutation_response["errors"]).to be_empty
        end
      end

      context "when too many vulnerabilities are passed" do
        before do
          stub_const("::Vulnerabilities::BulkDismissService::MAX_BATCH", 1)
        end

        it_behaves_like 'a mutation that returns top-level errors', errors: [/Maximum vulnerability_ids exceeded \(1\)/]
      end

      context "when vulnerability_id is nil" do
        let(:vulnerability_ids) { [nil] }

        it_behaves_like 'a mutation that returns top-level errors', errors: [/Expected value to not be null/]
      end

      context "when vulnerability_ids are empty" do
        let(:vulnerability_ids) { [] }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ["At least 1 value must be provided for vulnerability_ids"]
      end
    end
  end
end
