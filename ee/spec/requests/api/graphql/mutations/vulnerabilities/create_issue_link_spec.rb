# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Creating Issue Links", feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:vulnerability_1) { create(:vulnerability, project: project) }
  let_it_be(:vulnerability_2) { create(:vulnerability, project: project) }

  let(:vulnerabilities) { [vulnerability_1, vulnerability_2] }
  let(:issue_global_id) { issue.to_global_id.to_s }
  let(:vulnerability_global_ids) { vulnerabilities.map { |v| v.to_global_id.to_s } }

  subject(:mutation) do
    params = {
      issue_id: issue_global_id,
      vulnerability_ids: vulnerability_global_ids
    }

    graphql_mutation(:vulnerability_issue_link_create, params)
  end

  def mutation_response
    graphql_mutation_response(:vulnerability_issue_link_create)
  end

  context "when the user does not have access" do
    it_behaves_like "a mutation that returns a top-level access error"
  end

  context "when the user has access" do
    before do
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

      it "creates the issue links", :aggregate_failures do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { ::Vulnerabilities::IssueLink.count }.by(2)

        response_issue_link_gids = mutation_response["issueLinks"].map do |issue_link|
          issue_link.fetch("id")
        end
        expected_issue_link_gids = issue.reload.vulnerability_links.map do |issue_link|
          issue_link.to_global_id.to_s
        end

        expect(response_issue_link_gids).to match_array(expected_issue_link_gids)
        expect(response_issue_link_gids.count).to eq 2
      end

      context "when too many vulnerabilities are passed" do
        before do
          stub_const("::Mutations::Vulnerabilities::CreateIssueLink::MAX_VULNERABILITIES", 1)
        end

        it_behaves_like 'a mutation that returns top-level errors', errors: [/Maximum vulnerability_ids exceeded \(1\)/]
      end

      context "when the user does not have access to the issue" do
        let_it_be(:issue) { create(:issue) }

        it_behaves_like "a mutation that returns a top-level access error"
      end

      context "when issue_id is nil" do
        let(:issue_global_id) { nil }

        it_behaves_like 'a mutation that returns top-level errors', errors: [/Expected value to not be null/]
      end

      context "when vulnerability_id is nil" do
        let(:vulnerability_global_ids) { [nil] }

        it_behaves_like 'a mutation that returns top-level errors', errors: [/Expected value to not be null/]
      end

      context "when vulnerability_ids are empty" do
        let(:vulnerability_global_ids) { [] }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ["At least 1 value must be provided for vulnerability_ids"]
      end
    end
  end
end
