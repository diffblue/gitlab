# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an instance external audit event destination header', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let_it_be(:current_user) { admin }

  let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_create, input) }
  let(:mutation_response) { graphql_mutation_response(:audit_events_streaming_instance_headers_create) }

  let(:input) do
    {
      destinationId: destination.to_gid,
      key: 'foo',
      value: 'bar'
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    allow(Gitlab::Audit::Type::Definition).to receive(:defined?).and_return(true)
  end

  shared_examples 'a mutation that does not create a header' do
    it 'does not create a header' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { destination.headers.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when feature flag `ff_external_audit_events` is enabled' do
      context 'when current user is instance admin' do
        it 'creates the header with the correct attributes', :aggregate_failures do
          expect { subject }
            .to change { destination.headers.count }.by(1)

          header = AuditEvents::Streaming::InstanceHeader.last

          expect(header.key).to eq('foo')
          expect(header.value).to eq('bar')
          expect(mutation_response['errors']).to be_empty
        end

        context 'when the header attributes are invalid' do
          let_it_be(:invalid_headers_input) do
            {
              destinationId: destination.to_gid,
              key: '',
              value: 'bar'
            }
          end

          let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_create, invalid_headers_input) }

          it 'returns correct errors' do
            subject

            expect(mutation_response['header']).to be_nil
            expect(mutation_response['errors']).to contain_exactly("Key can't be blank")
          end

          it_behaves_like 'a mutation that does not create a header' do
            let_it_be(:current_user) { admin }
          end
        end

        context 'when the destination id is wrong' do
          let_it_be(:invalid_destination_input) do
            {
              destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/14566",
              key: 'foo',
              value: 'bar'
            }
          end

          let(:mutation) do
            graphql_mutation(:audit_events_streaming_instance_headers_create, invalid_destination_input)
          end

          it_behaves_like 'a mutation that returns top-level errors',
            errors: [Mutations::AuditEvents::Streaming::InstanceHeaders::Base::DESTINATION_ERROR_MESSAGE]

          it 'does not create any header' do
            expect { post_graphql_mutation(mutation, current_user: current_user) }
              .not_to change { AuditEvents::Streaming::InstanceHeader.count }
          end
        end
      end

      context 'when current user is not instance admin' do
        it_behaves_like 'a mutation that does not create a header' do
          let_it_be(:current_user) { user }
        end
      end
    end

    context 'when feature flag `ff_external_audit_events` is disabled' do
      before do
        stub_feature_flags(ff_external_audit_events: false)
      end

      context 'when current user is instance admin' do
        it_behaves_like 'a mutation that does not create a header' do
          let_it_be(:current_user) { admin }
        end
      end

      context 'when current user is not instance admin' do
        it_behaves_like 'a mutation that does not create a header' do
          let_it_be(:current_user) { user }
        end
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Mutations::AuditEvents::Streaming::InstanceHeaders::Base::ERROR_MESSAGE]

    it_behaves_like 'a mutation that does not create a header'
  end
end
