# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroy an external audit event destination header', feature_category: :audit_events do
  include GraphqlHelpers

  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:header) { create(:audit_events_streaming_header, external_audit_event_destination: destination) }

  let(:current_user) { owner }
  let(:group) { destination.group }
  let(:mutation) { graphql_mutation(:audit_events_streaming_headers_destroy, input) }
  let(:mutation_response) { graphql_mutation_response(:audit_events_streaming_headers_destroy) }

  let(:input) do
    { 'headerId': header.to_gid }
  end

  shared_examples 'a mutation that does not destroy a header' do
    it 'does not destroy the destination' do
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

      it 'destroys the header' do
        expect { subject }
          .to change { destination.headers.count }.by(-1)
      end

      context 'when header ID belongs to a different destination' do
        let_it_be(:header) { create(:audit_events_streaming_header) }

        it_behaves_like 'a mutation that does not destroy a header'
      end
    end

    context 'when current user is a group maintainer' do
      before do
        group.add_maintainer(owner)
      end

      it_behaves_like 'a mutation that does not destroy a header'
    end

    context 'when current user is a group developer' do
      before do
        group.add_developer(owner)
      end

      it_behaves_like 'a mutation that does not destroy a header'
    end

    context 'when current user is a group guest' do
      before do
        group.add_guest(owner)
      end

      it_behaves_like 'a mutation that does not destroy a header'
    end
  end

  context 'when feature is unlicensed' do
    before do
      stub_licensed_features(external_audit_events: false)
    end

    it_behaves_like 'a mutation on an unauthorized resource'

    it 'does not destroy the header' do
      expect { post_graphql_mutation(mutation, current_user: owner) }
        .not_to change { destination.headers.count }
    end
  end
end
