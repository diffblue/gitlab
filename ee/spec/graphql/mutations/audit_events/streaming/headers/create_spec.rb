# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AuditEvents::Streaming::Headers::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:destination) { create(:external_audit_event_destination) }

  let(:group) { destination.group }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:params) do
    {
      destination_id: destination.to_gid,
      key: 'foo',
      value: 'bar'
    }
  end

  subject { mutation.resolve(**params) }

  describe '#resolve' do
    context 'feature is unlicensed' do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it 'is not authorized' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'current_user is not group owner' do
        it 'returns useful error messages' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'current_user is group owner' do
        before do
          group.add_owner(current_user)
        end

        it 'creates a new header' do
          expect { subject }.to change { destination.headers.count }.by 1
        end
      end
    end
  end
end
