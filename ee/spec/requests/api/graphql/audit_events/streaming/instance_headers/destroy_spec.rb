# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy an external audit event destination header', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let_it_be(:header) do
    create(:instance_audit_events_streaming_header, instance_external_audit_event_destination: destination)
  end

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:current_user) { admin }
  let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_destroy, input) }
  let(:mutation_response) { graphql_mutation_response(:audit_events_streaming_instance_headers_destroy) }

  let(:input) do
    {
      headerId: header.to_gid
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a mutation that does not destroy a header' do
    it 'does not destroy the destination' do
      expect { post_graphql_mutation(mutation, current_user: actioner) }
        .not_to change { destination.headers.count }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is instance admin' do
      it 'destroys the header' do
        expect { subject }
          .to change { destination.headers.count }.by(-1)
      end

      context 'when the header id is wrong' do
        let_it_be(:invalid_header_input) do
          {
            headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/#{non_existing_record_id}"
          }
        end

        let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_destroy, invalid_header_input) }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

        it_behaves_like 'a mutation that does not destroy a header' do
          let_it_be(:actioner) { admin }
        end
      end

      context 'when there is an error while deleting header' do
        before do
          allow_next_found_instance_of(AuditEvents::Streaming::InstanceHeader) do |instance|
            allow(instance).to receive(:destroy).and_return(false)
            allow(instance).to receive(:errors).and_return('foo_error')
          end
        end

        it 'returns correct error' do
          expect { subject }
            .to change { destination.headers.count }.by(0)

          expect(mutation_response['errors']).to contain_exactly("foo_error")
        end
      end
    end

    context 'when current user is not instance admin' do
      it_behaves_like 'a mutation that does not destroy a header' do
        let_it_be(:actioner) { user }
      end
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation that returns top-level errors',
      errors: [Mutations::AuditEvents::Streaming::InstanceHeaders::Base::ERROR_MESSAGE]

    it_behaves_like 'a mutation that does not destroy a header' do
      let_it_be(:actioner) { admin }
    end
  end
end
