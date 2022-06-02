# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap::DeactivateMembersOverLimitService, :saas do
  before do
    stub_const('::Namespaces::FreeUserCap::FREE_USER_LIMIT', 2)
  end

  describe '#execute' do
    let_it_be(:group) { create(:group_with_plan, plan: :free_plan) }

    before do
      create_list(:group_member, 5, :active, source: group)
    end

    it 'deactivates active members' do
      expect { described_class.new(group).execute }
        .to change { group.members.awaiting.count }.from(0).to(3)
    end

    it 'logs an info' do
      expect(Gitlab::AppLogger).to receive(:info).with({
        namespace: group.id,
        message: 'Deactivated all members over the free user limit'
      })

      described_class.new(group).execute
    end

    it 'calls UserProjectAccessChangedService' do
      expect_next_instance_of(UserProjectAccessChangedService) do |service|
        expect(service)
          .to receive(:execute)
                .with(
                  blocking: false,
                  priority: UserProjectAccessChangedService::LOW_PRIORITY)
      end

      described_class.new(group).execute
    end

    context 'when an error occurs' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:deactivate_memberships).and_raise('An exception')
        end
      end

      it 'logs an error' do
        expect(Gitlab::AppLogger).to receive(:error).with({
          namespace: group.id,
          message: 'An error has occurred',
          details: 'An exception'
        })

        described_class.new(group).execute
      end
    end
  end
end
