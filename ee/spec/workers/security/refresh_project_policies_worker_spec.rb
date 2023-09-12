# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Security::RefreshProjectPoliciesWorker, feature_category: :security_policy_management do
  let(:project_member_changed_event) do
    ::ProjectAuthorizations::AuthorizationsChangedEvent.new(data: { project_id: 123 })
  end

  let(:worker) { ::Security::ScanResultPolicies::SyncProjectWorker }

  it_behaves_like 'subscribes to event' do
    let(:event) { project_member_changed_event }

    it 'receives the event after some delay' do
      expect(described_class).to receive(:perform_in).with(1.minute, any_args)
      ::Gitlab::EventStore.publish(event)
    end
  end

  it 'invokes ::Security::ScanResultPolicies::SyncProjectWorker with the project_id' do
    consume_event(subscriber: described_class, event: project_member_changed_event)

    expect_any_instance_of(worker) do |instance|
      expect(instance).to receive(:perform).with(123)
    end
  end
end
