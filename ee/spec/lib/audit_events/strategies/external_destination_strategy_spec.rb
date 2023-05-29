# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Strategies::ExternalDestinationStrategy, feature_category: :audit_events do
  let(:group) { build(:group) }
  let(:event) { build(:audit_event, :group_event, target_group: group) }
  let_it_be(:event_type) { 'audit_operation' }

  describe '#streamable?' do
    subject { described_class.new(event_type, event).streamable? }

    it 'raises NotImplementedError' do
      expect { subject }.to raise_error(NotImplementedError,
        AuditEvents::Strategies::ExternalDestinationStrategy::STREAMABLE_ERROR_MESSAGE)
    end
  end

  describe '#destinations' do
    subject { described_class.new(event_type, event).send(:destinations) }

    it 'raises NotImplementedError' do
      expect { subject }.to raise_error(NotImplementedError,
        AuditEvents::Strategies::ExternalDestinationStrategy::DESTINATIONS_ERROR_MESSAGE)
    end
  end

  describe '#execute' do
    let(:instance) { described_class.new(event_type, event) }

    subject { instance.execute }

    context 'when allowed to stream' do
      before do
        allow(instance).to receive(:streamable?).and_return(true)
      end

      context 'when a destination exists' do
        let!(:destination) { create(:external_audit_event_destination, group: group) }

        before do
          allow(instance).to receive(:destinations).and_return([destination])
        end

        include_examples 'streams audit events to external destination'

        include_examples 'redis connection failure for audit event counter'

        include_examples 'audit event external destination http post error'
      end

      context 'when multiple destinations exist' do
        let!(:destination1) { create(:external_audit_event_destination, group: group) }
        let!(:destination2) { create(:external_audit_event_destination, group: group) }

        before do
          allow(instance).to receive(:destinations).and_return([destination1, destination2])
        end

        include_examples 'streams audit events to several external destinations'
      end

      context 'when no destination exist' do
        before do
          allow(instance).to receive(:destinations).and_return([])
        end

        include_examples 'does not stream anywhere'
      end
    end

    context 'when not allowed to stream' do
      context 'when a destination exists' do
        let!(:destination) { create(:external_audit_event_destination, group: group) }

        before do
          allow(instance).to receive(:streamable?).and_return(false)
          allow(instance).to receive(:destinations).and_return([destination])
        end

        include_examples 'does not stream anywhere'
      end
    end
  end
end
