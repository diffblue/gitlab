# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AuditEvents::Streaming::Headers::Destroy do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:header) { create(:audit_events_streaming_header) }

  let(:destination) { header.external_audit_event_destination }
  let(:group) { destination.group }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  subject { mutation.resolve(**{ header_id: header.to_gid }) }

  describe '#resolve' do
    context 'feature is unlicensed' do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it 'is not authorized' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'The resource that you '\
                 'are attempting to access does not exist or you don\'t have permission to perform this action')
      end
    end

    context 'feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'current_user is not group owner' do
        it 'returns useful error messages' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'The resource that you '\
                 'are attempting to access does not exist or you don\'t have permission to perform this action')
        end
      end

      context 'current_user is group owner' do
        before do
          group.add_owner(current_user)
        end

        it 'deletes the header' do
          expect { subject }.to change { destination.headers.count }.by(-1)
        end

        context 'when destroy fails' do
          before do
            allow_next_found_instance_of(AuditEvents::Streaming::Header) do |header|
              allow(header).to receive(:destroy).and_return(false)
            end
          end

          it 'does not delete any headers' do
            expect { subject }.not_to change { destination.headers.count }
          end
        end
      end
    end
  end
end
