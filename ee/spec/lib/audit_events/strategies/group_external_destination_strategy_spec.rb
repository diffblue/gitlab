# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Strategies::GroupExternalDestinationStrategy, feature_category: :audit_events do
  let(:group) { build(:group) }
  let(:event) { build(:audit_event, :group_event, target_group: group) }
  let_it_be(:event_type) { 'audit_operation' }

  describe '#streamable?' do
    subject { described_class.new(event_type, event).streamable? }

    context 'when feature is not licensed' do
      it { is_expected.to be_falsey }
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when event group is nil' do
        let_it_be(:event) { build(:audit_event) }

        it { is_expected.to be_falsey }
      end

      context 'when group external destinations does not exist' do
        it { is_expected.to be_falsey }
      end

      context 'when group external destinations exist' do
        before do
          create(:external_audit_event_destination, group: group)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#destinations' do
    subject { described_class.new(event_type, event).send(:destinations) }

    context 'when event group is nil' do
      let_it_be(:event) { build(:audit_event) }

      it 'returns empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when group external destinations exist' do
      it 'returns all the destinations' do
        destination1 =  create(:external_audit_event_destination, group: group)
        destination2 =  create(:external_audit_event_destination, group: group)

        expect(subject).to match_array([destination1, destination2])
      end
    end
  end

  describe '#execute' do
    subject { described_class.new(event_type, event).execute }

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when a group destination exists' do
        let!(:destination) { create(:external_audit_event_destination, group: group) }

        context 'when the event entity type is a group' do
          include_examples 'streams audit events to external destination'
        end

        context 'when the event entity type is a project that belongs to a group' do
          let(:project) { create(:project, group: group) }
          let(:event) { create(:audit_event, :project_event, target_project: project) }

          include_examples 'streams audit events to external destination'
        end

        context 'when the event entity type is a project at a root namespace level' do
          let_it_be(:event) { create(:audit_event, :project_event) }

          include_examples 'does not stream anywhere'
        end

        context 'when the entity is a NullEntity' do
          let_it_be(:event) { create(:audit_event) }

          include_examples 'does not stream anywhere'
        end

        context 'when the destination has custom headers' do
          it 'sends the headers with the payload' do
            create_list(:audit_events_streaming_header, 2, external_audit_event_destination: destination)

            # rubocop:disable Lint/DuplicateHashKey
            expected_hash = {
              /key-\d/ => "bar",
              /key-\d/ => "bar"
            }
            # rubocop:enable Lint/DuplicateHashKey

            expect(Gitlab::HTTP).to receive(:post).with(
              an_instance_of(String), a_hash_including(headers: a_hash_including(expected_hash))
            ).once

            subject
          end
        end

        context 'when no event type filter is present' do
          it 'makes one HTTP call' do
            expect(Gitlab::HTTP).to receive(:post).once

            subject
          end
        end

        context 'when audit_operation streaming event type filter is not present' do
          before do
            create(
              :audit_events_streaming_event_type_filter,
              external_audit_event_destination: group.external_audit_event_destinations.last,
              audit_event_type: 'some_audit_operation'
            )
          end

          include_examples 'does not stream anywhere'
        end

        context 'when audit_operation streaming event type filter is present' do
          before do
            create(
              :audit_events_streaming_event_type_filter,
              external_audit_event_destination: group.external_audit_event_destinations.last,
              audit_event_type: event_type
            )
            create(
              :audit_events_streaming_event_type_filter,
              external_audit_event_destination: group.external_audit_event_destinations.last,
              audit_event_type: 'some_audit_operation'
            )
          end

          it 'makes one HTTP call' do
            expect(Gitlab::HTTP).to receive(:post).once

            subject
          end
        end
      end
    end

    context 'when the feature is not licensed' do
      before do
        create(:external_audit_event_destination, group: group)
      end

      include_examples 'does not stream anywhere'
    end
  end
end
