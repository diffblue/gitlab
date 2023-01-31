# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Mutations::Security::Finding::RevertToDetected, feature_category: :vulnerability_management do
  include GraphqlHelpers

  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  describe '#resolve' do
    let_it_be(:security_finding) { create(:security_finding, :with_finding_data) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:finding_uuid) { security_finding.uuid }
    let_it_be(:mutation_input) { { uuid: security_finding.uuid.to_s } }
    let_it_be(:error_message) { 'dismissal failed' }
    let_it_be(:error_result) do
      ServiceResponse.error(message: error_message, reason: :unprocessable_entity)
    end

    let(:mutated_finding_uuid) { subject[:uuid] }

    let(:mutation) do
      graphql_mutation(
        :security_finding_revert_to_detected,
        mutation_input
      ) do
        <<~QL
           clientMutationId
           errors
           securityFinding {
             uuid
             description
             state
           }
        QL
      end
    end

    let(:mutation_response) { graphql_mutation_response(:security_finding_revert_to_detected) }
    let(:response_finding) { mutation_response['securityFinding'] }

    context 'when the user has access to vulnerability management' do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      context 'when user does not have access to the project' do
        it_behaves_like 'a mutation that returns a top-level access error'
      end

      context 'when no uuid is provided' do
        let_it_be(:mutation_input) { {} }

        let(:error_message) { graphql_errors.first['message'] }

        it 'raises an error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(error_message).to include('Expected value to not be null')
        end
      end

      context 'when the user has access to the project' do
        let_it_be(:expected_finding) do
          security_finding.slice(
            :uuid,
            :description
          ).merge('state' => 'DETECTED')
        end

        before do
          security_finding.project.add_developer(current_user)
        end

        shared_examples 'properly sets the security finding state' do
          it 'sets the security finding state to detected' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(response_finding).to match(expected_finding)
            security_finding.reset
            expect(security_finding.state).to eq('detected')
          end
        end

        shared_examples 'properly sets the vulnerability state' do
          it 'sets the vulnerability state to detected' do
            post_graphql_mutation(mutation, current_user: current_user)

            expect(vulnerability.state).to eq('detected')
          end
        end

        context 'when there is a dismissal feedback' do
          let_it_be(:dismissal_feedback) do
            create(:vulnerability_feedback,
                   :dismissal,
                   finding_uuid: security_finding.uuid,
                   project: security_finding.project)
          end

          context 'when there is no vulnerability' do
            it_behaves_like 'properly sets the security finding state'
          end

          context 'when there is a vulnerability' do
            let_it_be(:vulnerability) { create(:vulnerability, project: security_finding.project) }
            let_it_be(:vulnerability_finding) do
              create(:vulnerabilities_finding, vulnerability: vulnerability, uuid: finding_uuid)
            end

            it_behaves_like 'properly sets the security finding state'
            it_behaves_like 'properly sets the vulnerability state'

            context 'when the dismissal fails' do
              before do
                allow_next_instance_of(::Vulnerabilities::RevertToDetectedService) do |service|
                  allow(service).to receive(:execute).and_return(error_result)
                end
              end

              it 'raises an error' do
                post_graphql_mutation(mutation, current_user: current_user)

                expect(mutation_response['errors']).to match_array([error_message])
              end
            end
          end

          context 'when the dismissal fails' do
            before do
              allow_next_instance_of(::VulnerabilityFeedback::DestroyService) do |service|
                allow(service).to receive(:execute).and_return(error_result)
              end
            end

            it 'raises an error' do
              post_graphql_mutation(mutation, current_user: current_user)

              expect(mutation_response['errors']).to match_array([error_message])
            end
          end
        end

        context 'when there is no dismissal feedback' do
          context 'when there is no vulnerability' do
            it_behaves_like 'properly sets the security finding state'
          end

          context 'when there is a vulnerability' do
            let_it_be(:vulnerability) { create(:vulnerability, project: security_finding.project) }
            let_it_be(:vulnerability_finding) do
              create(:vulnerabilities_finding, vulnerability: vulnerability, uuid: finding_uuid)
            end

            it_behaves_like 'properly sets the security finding state'
            it_behaves_like 'properly sets the vulnerability state'
          end
        end
      end
    end

    context 'when the security dashboard is not available to the user' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end
  end
end
