# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Security::Finding::Dismiss do
  include GraphqlHelpers

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    let_it_be(:security_finding) { create(:security_finding) }
    let_it_be(:user) { create(:user) }
    let_it_be(:finding_uuid) { security_finding.uuid }

    let(:comment) { 'Dismissal Feedback' }
    let(:mutated_finding_uuid) { subject[:uuid] }
    let(:mutated_finding) { subject[:security_finding] }

    subject { mutation.resolve(uuid: finding_uuid, comment: comment, dismissal_reason: 'used_in_tests') }

    context 'when the user has permission to dismiss the security finding' do
      before do
        stub_licensed_features(security_dashboard: true)
        stub_feature_flags(deprecate_vulnerabilities_feedback: false)
      end

      context 'when user does not have access to the project' do
        it 'raises an error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when no uuid is provided' do
        subject { mutation.resolve(comment: comment, dismissal_reason: 'used_in_tests') }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'when the user has access to the project' do
        before do
          security_finding.project.add_developer(user)
        end

        context 'when the dismissal is successful' do
          it 'returns the dismissed security finding uuid' do
            expect(mutated_finding_uuid).to eq(finding_uuid)
            expect(subject[:errors]).to be_empty
          end

          it 'returns the dismissed security finding' do
            expect(mutated_finding).to eq(security_finding)
            expect(subject[:errors]).to be_empty
          end
        end

        context 'when the dismissal fails' do
          let_it_be(:error_result) do
            ServiceResponse.error(message: "error", http_status: :unprocessable_entity)
          end

          before do
            allow_next_instance_of(::Security::Findings::DismissService) do |service|
              allow(service).to receive(:execute).and_return(error_result)
            end
          end

          it 'raises an error and no uuid is returned' do
            expect(mutated_finding_uuid).to be_nil
            expect(subject[:errors]).to match_array(['error'])
          end

          it 'raises an error and no security finding is returned' do
            expect(mutated_finding).to be_nil
            expect(subject[:errors]).to match_array(['error'])
          end
        end
      end
    end

    context 'when the security dashboard is not available to the user' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
