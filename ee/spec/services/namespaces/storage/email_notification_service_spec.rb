# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::EmailNotificationService do
  include NamespaceStorageHelpers
  using RSpec::Parameterized::TableSyntax

  describe 'execute' do
    let(:mailer) { class_double(::Emails::NamespaceStorageUsageMailer) }
    let(:action_mailer) { instance_double(ActionMailer::MessageDelivery) }
    let(:service) { described_class.new(mailer) }

    context 'in a saas environment', :saas do
      let_it_be(:group, refind: true) { create(:group_with_plan, plan: :ultimate_plan) }
      let_it_be(:owner) { create(:user) }

      before_all do
        create(:namespace_root_storage_statistics, namespace: group)
        group.add_owner(owner)
      end

      where(:limit, :used, :last_notification_level, :expected_level) do
        100 | 100 | :storage_remaining | :exceeded
        100 | 200 | :storage_remaining | :exceeded
        100 | 100 | :caution           | :exceeded
        100 | 100 | :warning           | :exceeded
        100 | 100 | :danger            | :exceeded
      end

      with_them do
        it 'sends an out of storage notification when the namespace runs out of storage' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: used)
          set_notification_level(last_notification_level)

          expect(mailer).to receive(:notify_out_of_storage).with(group, [owner.email])
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(group)

          expect(group.root_storage_statistics.reload.notification_level.to_sym).to eq(expected_level)
        end
      end

      where(:limit, :used, :last_notification_level, :expected_percent, :expected_size, :expected_level) do
        100  | 70   | :storage_remaining | 30 | 30.megabytes   | :caution
        100  | 85   | :storage_remaining | 15 | 15.megabytes   | :warning
        100  | 95   | :storage_remaining | 5  | 5.megabytes    | :danger
        100  | 77   | :storage_remaining | 23 | 23.megabytes   | :caution
        1000 | 971  | :storage_remaining | 2  | 29.megabytes   | :danger
        100  | 85   | :caution           | 15 | 15.megabytes   | :warning
        100  | 95   | :warning           | 5  | 5.megabytes    | :danger
        100  | 99   | :exceeded          | 1  | 1.megabytes    | :danger
        100  | 94   | :danger            | 6  | 6.megabytes    | :warning
        100  | 84   | :warning           | 16 | 16.megabytes   | :caution
        8192 | 6144 | :storage_remaining | 25 | 2.gigabytes    | :caution
        5120 | 3840 | :storage_remaining | 25 | 1.25.gigabytes | :caution
        5120 | 5118 | :warning           | 0  | 2.megabytes    | :danger
      end

      with_them do
        it 'sends a storage limit notification when storage is running low' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: used)
          set_notification_level(last_notification_level)

          expect(mailer).to receive(:notify_limit_warning).with(group, [owner.email], expected_percent, expected_size)
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(group)

          expect(group.root_storage_statistics.reload.notification_level.to_sym).to eq(expected_level)
        end
      end

      where(:limit, :used, :last_notification_level) do
        100  | 5   | :storage_remaining
        100  | 69  | :storage_remaining
        100  | 69  | :caution
        100  | 69  | :warning
        100  | 69  | :danger
        100  | 69  | :exceeded
        1000 | 699 | :exceeded
      end

      with_them do
        it 'does not send an email when there is sufficient storage remaining' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: used)
          set_notification_level(last_notification_level)

          expect(mailer).not_to receive(:notify_out_of_storage)
          expect(mailer).not_to receive(:notify_limit_warning)

          service.execute(group)
        end
      end

      where(:limit, :used, :last_notification_level) do
        0    | 0   | :storage_remaining
        0    | 150 | :storage_remaining
        0    | 0   | :caution
        0    | 100 | :caution
        0    | 0   | :warning
        0    | 50  | :warning
        0    | 0   | :danger
        0    | 50  | :danger
        0    | 0   | :exceeded
        0    | 1   | :exceeded
      end

      with_them do
        it 'does not send an email when there is no storage limit' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: used)
          set_notification_level(last_notification_level)

          expect(mailer).not_to receive(:notify_out_of_storage)
          expect(mailer).not_to receive(:notify_limit_warning)

          service.execute(group)

          expect(group.root_storage_statistics.reload.notification_level.to_sym).to eq(:storage_remaining)
        end
      end

      it 'sends an email to all group owners' do
        set_storage_size_limit(group, megabytes: 100)
        set_used_storage(group, megabytes: 200)
        owner2 = create(:user)
        group.add_owner(owner2)
        group.add_maintainer(create(:user))
        group.add_developer(create(:user))
        group.add_reporter(create(:user))
        group.add_guest(create(:user))
        owner_emails = [owner.email, owner2.email]

        expect(mailer).to receive(:notify_out_of_storage).with(group, match_array(owner_emails))
          .and_return(action_mailer)
        expect(action_mailer).to receive(:deliver_later)

        service.execute(group)
      end

      it 'does not send an out of storage notification twice' do
        set_storage_size_limit(group, megabytes: 100)
        set_used_storage(group, megabytes: 200)
        set_notification_level(:exceeded)

        expect(mailer).not_to receive(:notify_out_of_storage)

        service.execute(group)
      end

      where(:limit, :used, :last_notification_level) do
        100  | 70  | :caution
        100  | 85  | :warning
        100  | 95  | :danger
      end

      with_them do
        it 'does not send a storage limit notification for the same threshold twice' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: used)
          set_notification_level(last_notification_level)

          expect(mailer).not_to receive(:notify_limit_warning)

          service.execute(group)
        end
      end

      it 'does nothing if there is no root_storage_statistics' do
        group.root_storage_statistics.destroy!
        group.reload

        expect(mailer).not_to receive(:notify_out_of_storage)
        expect(mailer).not_to receive(:notify_limit_warning)

        service.execute(group)

        expect(group.reload.root_storage_statistics).to be_nil
      end

      context 'with a personal namespace' do
        let_it_be(:namespace) { create(:namespace_with_plan, plan: :ultimate_plan) }

        before_all do
          create(:namespace_root_storage_statistics, namespace: namespace)
        end

        it 'sends a limit notification' do
          set_storage_size_limit(namespace, megabytes: 1000)
          set_used_storage(namespace, megabytes: 851)
          owner = namespace.owner

          expect(mailer).to receive(:notify_limit_warning).with(namespace, [owner.email], 14, 149.megabytes)
          .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(namespace)
        end

        it 'sends an out of storage notification' do
          set_storage_size_limit(namespace, megabytes: 100)
          set_used_storage(namespace, megabytes: 550)
          owner = namespace.owner

          expect(mailer).to receive(:notify_out_of_storage).with(namespace, [owner.email])
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(namespace)
        end
      end
    end

    context 'in a self-managed environment' do
      it 'does nothing' do
        group = create(:group)
        create(:namespace_root_storage_statistics, namespace: group)
        owner = create(:user)
        group.add_owner(owner)
        set_used_storage(group, megabytes: 87)

        expect(mailer).not_to receive(:notify_out_of_storage)
        expect(mailer).not_to receive(:notify_limit_warning)

        service.execute(group)

        expect(group.root_storage_statistics.reload.notification_level).to eq('storage_remaining')
      end
    end
  end

  def set_notification_level(level)
    group.root_storage_statistics.update!(notification_level: level)
  end
end
