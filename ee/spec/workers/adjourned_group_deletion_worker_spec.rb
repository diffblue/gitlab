# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdjournedGroupDeletionWorker, feature_category: :compliance_management do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let_it_be(:user) { create(:user) }
    let_it_be(:group_not_marked_for_deletion) { create(:group) }

    let_it_be(:group_marked_for_deletion) do
      create(
        :group_with_deletion_schedule,
        marked_for_deletion_on: 14.days.ago,
        deleting_user: user
      )
    end

    let_it_be(:group_marked_for_deletion_for_later) do
      create(
        :group_with_deletion_schedule,
        marked_for_deletion_on: 2.days.ago,
        deleting_user: user
      )
    end

    before do
      stub_application_setting(deletion_adjourned_period: 14)
    end

    it 'only schedules to delete groups marked for deletion on or before the specified `deletion_adjourned_period`' do
      expect(GroupDestroyWorker).to receive(:perform_in).with(0, group_marked_for_deletion.id, user.id)

      worker.perform
    end

    it 'does not schedule to delete a group not marked for deletion' do
      expect(GroupDestroyWorker).not_to receive(:perform_in).with(0, group_not_marked_for_deletion.id, user.id)

      worker.perform
    end

    it 'does not schedule to delete a group that is marked for deletion after the specified `deletion_adjourned_period`' do
      expect(GroupDestroyWorker).not_to receive(:perform_in).with(0, group_marked_for_deletion_for_later.id, user.id)

      worker.perform
    end

    it 'schedules groups 20 seconds apart' do
      group_marked_for_deletion_2 = create(
        :group_with_deletion_schedule,
        marked_for_deletion_on: 14.days.ago,
        deleting_user: user
      )

      expect(GroupDestroyWorker).to receive(:perform_in).with(0, group_marked_for_deletion.id, user.id)
      expect(GroupDestroyWorker).to receive(:perform_in).with(20, group_marked_for_deletion_2.id, user.id)

      worker.perform
    end
  end
end
