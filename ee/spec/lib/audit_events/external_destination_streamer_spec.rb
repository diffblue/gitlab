# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ExternalDestinationStreamer, feature_category: :audit_events do
  before do
    stub_licensed_features(external_audit_events: true)
  end

  describe '#stream_to_destinations' do
    let_it_be(:event) { create(:audit_event, :group_event) }
    let(:group) { event.entity }

    subject { described_class.new('audit_operation', event).stream_to_destinations }

    context 'when no external audit event destinations are present' do
      it 'does not make any HTTP call' do
        expect(Gitlab::HTTP).not_to receive(:post)

        subject
      end
    end

    context 'when external destinations are present' do
      before do
        create(:external_audit_event_destination, group: group)
        create_list(:instance_external_audit_event_destination, 2)
      end

      it 'makes two HTTP calls' do
        expect(Gitlab::HTTP).to receive(:post).thrice

        subject
      end
    end
  end

  describe '#streamable?' do
    let_it_be(:event) { create(:audit_event, :group_event) }
    let_it_be(:group) { event.entity }

    subject { described_class.new('audit_operation', event).streamable? }

    context 'when none of them is streamable' do
      it { is_expected.to be_falsey }
    end

    context 'when atleast one of them is streamable' do
      context 'when all of them are streamable' do
        before do
          create(:external_audit_event_destination, group: group)
          create(:instance_external_audit_event_destination)
        end

        it { is_expected.to be_truthy }
      end

      context 'when group is streamable but instance is not' do
        before do
          create(:external_audit_event_destination, group: group)
        end

        it { is_expected.to be_truthy }
      end

      context 'when instance is streamable but group is not' do
        before do
          create(:instance_external_audit_event_destination)
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
