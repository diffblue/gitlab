# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Resolve, feature_category: :vulnerability_management do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:vulnerability) { create(:vulnerability, :with_findings) }
    let_it_be(:user) { create(:user) }
    let(:comment) { "resolved vulnerability comment" }

    let(:mutated_vulnerability) { resolved_mutation[:vulnerability] }
    let(:created_state_transition) { mutated_vulnerability.state_transitions.last }

    subject(:resolved_mutation) { mutation.resolve(id: GitlabSchema.id_from_object(vulnerability), comment: comment) }

    context 'when the user can resolve the vulnerability' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user does not have access to the project' do
        it 'raises an error' do
          expect { resolved_mutation }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has access to the project', :aggregate_failures do
        before do
          vulnerability.project.add_developer(user)
        end

        it 'returns the resolved vulnerability' do
          expect(mutated_vulnerability).to eq(vulnerability)
          expect(mutated_vulnerability).to be_resolved
          expect(resolved_mutation[:errors]).to be_empty
          expect(created_state_transition.comment).to eq comment
        end

        context 'when no comment is passed' do
          subject(:resolved_mutation) { mutation.resolve(id: GitlabSchema.id_from_object(vulnerability)) }

          it 'returns the resolved vulnerability' do
            expect(mutated_vulnerability).to eq(vulnerability)
            expect(mutated_vulnerability).to be_resolved
            expect(resolved_mutation[:errors]).to be_empty
            expect(created_state_transition.comment).to be_nil
          end
        end
      end
    end
  end
end
