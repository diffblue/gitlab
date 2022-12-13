# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an external audit event destination header', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:owner) { create(:user) }

  let(:current_user) { owner }
  let(:group) { destination.group }
  let(:mutation) { graphql_mutation(:audit_events_streaming_headers_create, input) }
  let(:mutation_response) { graphql_mutation_response(:audit_events_streaming_headers_create) }

  let(:input) do
    {
      'destinationId': destination.to_gid,
      'key': 'foo',
      'value': 'bar'
    }
  end

  let(:invalid_input) do
    {
      'destinationId': destination.to_gid,
      'key': '',
      'value': 'bar'
    }
  end

  shared_examples 'a mutation that does not create a header' do
    it 'does not create a header' do
      expect { post_graphql_mutation(mutation, current_user: owner) }
        .not_to change { destination.headers.count }
    end
  end

  context 'when feature is licensed' do
    subject { post_graphql_mutation(mutation, current_user: owner) }

    before do
      stub_licensed_features(external_audit_events: true)
    end

    context 'when current user is a group owner' do
      before do
        group.add_owner(owner)
      end

      it 'creates the header with the correct attributes', :aggregate_failures do
        expect { subject }
          .to change { destination.headers.count }.by(1)

        header = AuditEvents::Streaming::Header.last

        expect(header.key).to eq('foo')
        expect(header.value).to eq('bar')
      end

      context 'when the header attributes are invalid' do
        let(:mutation) { graphql_mutation(:audit_events_streaming_headers_create, invalid_input) }

        it 'returns correct errors' do
          post_graphql_mutation(mutation, current_user: owner)

          expect(mutation_response['header']).to be_nil
          expect(mutation_response['errors']).to contain_exactly("Key can't be blank")
        end

        it_behaves_like 'a mutation that does not create a header'
      end
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(owner)
      end

      it_behaves_like 'a mutation that does not create a header'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'a mutation that does not create a header'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'a mutation that does not create a header'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'
    it_behaves_like 'a mutation that does not create a header'
  end
end
