# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Strategies::InstanceExternalDestinationStrategy, feature_category: :audit_events do
  let_it_be(:event) { create(:audit_event, :group_event) }
  let_it_be(:group) { event.entity }
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

      context 'when feature flag ff_external_audit_events is enabled' do
        context 'when there is no InstanceExternalAuditEventDestination' do
          it { is_expected.to be_falsey }
        end

        context 'when there is at least one InstanceExternalAuditEventDestination' do
          before do
            create(:instance_external_audit_event_destination)
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
          create(:instance_external_audit_event_destination)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#destinations' do
    subject { described_class.new(event_type, event).send(:destinations) }

    context 'when there is no destination' do
      it 'returns empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when instance external destinations exist' do
      let_it_be(:destination1) { create(:instance_external_audit_event_destination) }
      let_it_be(:destination2) { create(:instance_external_audit_event_destination) }

      it 'returns all the destinations' do
        expect(subject).to match_array([destination1, destination2])
      end
    end
  end

  describe '#execute' do
    subject { described_class.new('audit_operation', event).execute }

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when an instance destination exists' do
        let_it_be(:destination) { create(:instance_external_audit_event_destination) }

        context 'when the event entity type is a group' do
          include_examples 'streams audit events to external destination'
        end

        context 'when the event entity type is a project that belongs to a group' do
          let_it_be(:project) { create(:project, group: group) }
          let_it_be(:event) { create(:audit_event, :project_event, target_project: project) }

          include_examples 'streams audit events to external destination'
        end

        context 'when the event entity type is a project at a root namespace level' do
          let_it_be(:event) { create(:audit_event, :project_event) }

          include_examples 'streams audit events to external destination'
        end

        context 'when the entity is a NullEntity' do
          let_it_be(:event) { create(:audit_event) }

          include_examples 'streams audit events to external destination'
        end
      end
    end

    context 'when the feature is not licensed' do
      let_it_be(:destination) { create(:instance_external_audit_event_destination) }

      include_examples 'does not stream anywhere'
    end
  end
end
