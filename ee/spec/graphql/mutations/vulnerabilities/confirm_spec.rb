# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Confirm, feature_category: :vulnerability_management do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:vulnerability) { create(:vulnerability, :with_findings) }
    let_it_be(:user) { create(:user) }
    let_it_be(:comment) { "It's really there, I swear." }

    let(:mutated_vulnerability) { subject[:vulnerability] }
    let(:created_state_transition) { mutated_vulnerability.state_transitions.last }

    let(:params) do
      {
        id: GitlabSchema.id_from_object(vulnerability),
        comment: comment
      }
    end

    subject(:mutation_result) { mutation.resolve(**params) }

    context 'when the user can confirm the vulnerability' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user doe not have access to the project' do
        it 'raises an error' do
          expect { mutation_result }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has access to the project', :aggregate_failures do
        before do
          vulnerability.project.add_developer(user)
        end

        context 'when comment is not provided' do
          let(:params) { { id: GitlabSchema.id_from_object(vulnerability) } }

          it 'returns the Confirmed vulnerability' do
            expect(mutated_vulnerability).to eq(vulnerability)
            expect(mutated_vulnerability).to be_confirmed
            expect(created_state_transition.comment).to be_nil
            expect(mutation_result[:errors]).to be_empty
          end
        end

        it 'returns the Confirmed vulnerability' do
          expect(mutated_vulnerability).to eq(vulnerability)
          expect(mutated_vulnerability).to be_confirmed
          expect(created_state_transition.comment).to eq(comment)
          expect(mutation_result[:errors]).to be_empty
        end
      end
    end
  end
end
