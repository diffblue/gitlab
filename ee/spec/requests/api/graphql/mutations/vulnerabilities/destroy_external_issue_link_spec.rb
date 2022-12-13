# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an External Issue Link', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:vulnerability_external_issue_link) { create(:vulnerabilities_external_issue_link) }

  let(:mutation) do
    params = { id: vulnerability_external_issue_link.to_global_id.to_s }

    graphql_mutation(:vulnerability_external_issue_link_destroy, params)
  end

  def mutation_response
    graphql_mutation_response(:vulnerability_external_issue_link_destroy)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not destroy external issue link' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Vulnerabilities::ExternalIssueLink, :count)
    end
  end

  context 'when the user has permission' do
    before do
      vulnerability_external_issue_link.vulnerability.project.add_developer(current_user)
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
      end

      it 'destroys the external issue link' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(Vulnerabilities::ExternalIssueLink, :count).by(-1)
      end
    end
  end
end
