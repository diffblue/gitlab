# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::RevertToDetected, feature_category: :vulnerability_management do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_vulnerability) }

  describe '#resolve' do
    let_it_be(:vulnerability) { create(:vulnerability, :dismissed, :with_findings) }
    let_it_be(:user) { create(:user) }
    let_it_be(:comment) { "wheee" }

    let(:mutated_vulnerability) { subject[:vulnerability] }

    let(:params) do
      {
        id: GitlabSchema.id_from_object(vulnerability),
        comment: comment
      }
    end

    subject { mutation.resolve(**params) }

    context 'when the user can revert the vulnerability to detected' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user does not have access to the project' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has access to the project' do
        before do
          vulnerability.project.add_developer(user)
        end

        context 'and no comment is provided' do
          let(:params) { { id: GitlabSchema.id_from_object(vulnerability) } }

          it 'returns the vulnerability back in detected state', :aggregate_failures do
            expect(mutated_vulnerability).to eq(vulnerability)
            expect(mutated_vulnerability).to be_detected
            expect(subject[:errors]).to be_empty
            expect(vulnerability.state_transitions.last.comment).to be_nil
          end
        end

        it 'returns the vulnerability back in detected state', :aggregate_failures do
          expect(mutated_vulnerability).to eq(vulnerability)
          expect(mutated_vulnerability).to be_detected
          expect(subject[:errors]).to be_empty
          expect(vulnerability.state_transitions.last.comment).to eq(comment)
        end
      end
    end
  end
end
