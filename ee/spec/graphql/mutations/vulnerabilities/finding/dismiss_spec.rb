# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Vulnerabilities::Finding::Dismiss, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:finding) { create(:vulnerabilities_finding) }
    let_it_be(:user) { create(:user) }
    let_it_be(:finding_id) { global_id_of(finding) }
    let_it_be(:finding_uuid) { finding.uuid }

    let(:comment) { 'Dismissal Feedback' }
    let(:mutated_finding) { subject[:finding] }

    subject { mutation.resolve(uuid: finding_uuid, comment: comment, dismissal_reason: 'used_in_tests') }

    context 'when the user can dismiss the finding' do
      before do
        stub_licensed_features(security_dashboard: true)
        stub_feature_flags(deprecate_vulnerabilities_feedback: false)
      end

      shared_examples_for 'vulnerability finding dismissal' do
        it 'returns the dismissed finding' do
          expect(mutated_finding).to eq(finding)
          expect(mutated_finding.reload.state).to eq('dismissed')
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when user does not have access to the project' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when no id or uuid is provided' do
        subject { mutation.resolve(comment: comment, dismissal_reason: 'used_in_tests') }

        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
        end
      end

      context 'when user has access to the project' do
        before do
          finding.project.add_developer(user)
        end

        it_behaves_like 'vulnerability finding dismissal'

        context `when dismissing by id (deprecated)` do
          subject { mutation.resolve(id: finding_id, comment: comment, dismissal_reason: 'used_in_tests') }

          it_behaves_like 'vulnerability finding dismissal'
        end
      end
    end

    context 'when the user cannot dismiss the finding' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
