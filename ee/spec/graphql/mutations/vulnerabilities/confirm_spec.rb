# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Confirm, feature_category: :vulnerability_management do
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:vulnerability) { create(:vulnerability, :with_findings) }
    let_it_be(:user) { create(:user) }

    let(:mutated_vulnerability) { subject[:vulnerability] }

    subject { mutation.resolve(id: GitlabSchema.id_from_object(vulnerability)) }

    context 'when the user can confirm the vulnerability' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user doe not have access to the project' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when user has access to the project' do
        before do
          vulnerability.project.add_developer(user)
        end

        it 'returns the Confirmed vulnerability' do
          expect(mutated_vulnerability).to eq(vulnerability)
          expect(mutated_vulnerability).to be_confirmed
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
