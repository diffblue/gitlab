# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AuditEvents::Streaming::EventTypeFilters::Create, feature_category: :audit_events do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:destination) { create(:external_audit_event_destination) }

  let(:group) { destination.group }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:params) do
    {
      destination_id: destination.to_gid,
      event_type_filters: %w[filter_1]
    }
  end

  subject { mutation.resolve(**params) }

  describe '#resolve' do
    context 'when feature is unlicensed' do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it 'returns useful error messages' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when current_user is not group owner' do
        it 'returns useful error messages' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when current_user is group owner' do
        before do
          group.add_owner(current_user)
        end

        context 'and calls create service' do
          context 'when response is success' do
            let(:response) { ServiceResponse.success }

            before do
              allow_next_instance_of(::AuditEvents::Streaming::EventTypeFilters::CreateService) do |instance|
                allow(instance).to receive(:execute).and_return(response)
              end
            end

            it 'returns event type filters' do
              expect(subject).to eq({ event_type_filters: destination.event_type_filters, errors: [] })
            end
          end

          context 'when response is error' do
            let(:response) { ServiceResponse.error(message: 'Something went wrong') }

            before do
              allow_next_instance_of(::AuditEvents::Streaming::EventTypeFilters::CreateService) do |instance|
                allow(instance).to receive(:execute).and_return(response)
              end
            end

            it 'returns error message' do
              expect(subject).to eq({ event_type_filters: destination.event_type_filters,
                                      errors: ['Something went wrong'] })
            end
          end
        end
      end
    end
  end
end
