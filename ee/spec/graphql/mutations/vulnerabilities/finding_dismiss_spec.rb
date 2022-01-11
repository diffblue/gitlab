# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::FindingDismiss do
  include GraphqlHelpers

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:finding) { create(:vulnerabilities_finding) }
    let_it_be(:user) { create(:user) }
    let_it_be(:finding_id) { GitlabSchema.id_from_object(finding).to_s }

    let(:comment) { 'Dismissal Feedback' }
    let(:mutated_finding) { subject[:finding] }

    subject { mutation.resolve(id: finding_id, comment: comment, dismissal_reason: 'used_in_tests') }

    context 'when the user can dismiss the finding' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user does not have access to the project' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'with invalid params' do
        let(:finding_id) { global_id_of(user) }

        it 'raises an error' do
          expect { subject }.to raise_error(::GraphQL::CoercionError)
        end
      end

      context 'when user has access to the project' do
        before do
          finding.project.add_developer(user)
        end

        it 'returns the dismissed finding' do
          expect(mutated_finding).to eq(finding)
          expect(mutated_finding.state).to eq('dismissed')
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
