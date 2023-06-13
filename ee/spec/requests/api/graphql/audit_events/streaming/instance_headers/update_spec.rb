# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update an external audit event destination header', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let_it_be(:header) do
    create(:instance_audit_events_streaming_header,
      key: 'key-1',
      instance_external_audit_event_destination: destination
    )
  end

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  let(:current_user) { admin }
  let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_update, input) }
  let(:mutation_response) { graphql_mutation_response(:audit_events_streaming_instance_headers_update) }

  let(:input) do
    {
      headerId: header.to_gid,
      key: 'new-key',
      value: 'new-value'
    }
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'a mutation that does not update a header' do
    it 'does not update a header key' do
      expect { post_graphql_mutation(mutation, current_user: actioner) }.not_to change { header.key }
    end

    it 'does not update a header value' do
      expect { post_graphql_mutation(mutation, current_user: actioner) }.not_to change { header.value }
    end
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when feature flag `ff_external_audit_events` is enabled' do
      context 'when current user is instance admin' do
        it 'updates the header with the correct attributes', :aggregate_failures do
          expect { subject }.to change { header.reload.key }.from('key-1').to('new-key')
                                                            .and change { header.reload.value }.from('bar')
                                                                                               .to('new-value')
        end

        context 'when the header attributes are invalid' do
          let(:invalid_key_input) do
            {
              headerId: header.to_gid,
              key: '',
              value: 'bar'
            }
          end

          let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_update, invalid_key_input) }

          it 'returns correct errors' do
            subject

            expect(mutation_response['errors']).to contain_exactly("Key can't be blank")
          end

          it 'returns the unmutated attribute values', :aggregate_failures do
            subject

            expect(mutation_response.dig('header', 'key')).to eq('key-1')
            expect(mutation_response.dig('header', 'value')).to eq('bar')
          end

          it_behaves_like 'a mutation that does not update a header' do
            let_it_be(:actioner) { admin }
          end
        end

        context 'when the header id is wrong' do
          let_it_be(:invalid_header_input) do
            {
              headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/-1",
              key: 'foo',
              value: 'bar'
            }
          end

          let(:mutation) { graphql_mutation(:audit_events_streaming_instance_headers_update, invalid_header_input) }

          it_behaves_like 'a mutation that returns top-level errors',
            errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]

          it_behaves_like 'a mutation that does not update a header' do
            let_it_be(:actioner) { admin }
          end
        end
      end

      context 'when current user is not instance admin' do
        it_behaves_like 'a mutation that does not update a header' do
          let_it_be(:actioner) { user }
        end
      end
    end

    context 'when feature flag `ff_external_audit_events` is disabled' do
      before do
        stub_feature_flags(ff_external_audit_events: false)
      end

      context 'when current user is instance admin' do
        it_behaves_like 'a mutation that does not update a header' do
          let_it_be(:actioner) { admin }
        end
      end

      context 'when current user is not instance admin' do
        it_behaves_like 'a mutation that does not update a header' do
          let_it_be(:actioner) { user }
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

    it_behaves_like 'a mutation that does not update a header' do
      let_it_be(:actioner) { admin }
    end
  end
end
