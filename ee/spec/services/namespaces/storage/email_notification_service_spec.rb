# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Storage::EmailNotificationService, feature_category: :purchase do
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

      where(:limit, :current_size, :used_storage_percentage, :last_notification_level, :expected_level) do
        100 | 100 | 100 | :storage_remaining | :exceeded
        100 | 200 | 200 | :storage_remaining | :exceeded
        100 | 100 | 100 | :caution           | :exceeded
        100 | 100 | 100 | :warning           | :exceeded
        100 | 100 | 100 | :danger            | :exceeded
      end

      with_them do
        it 'sends an out of storage notification when the namespace runs out of storage' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: current_size)
          set_notification_level(last_notification_level)

          expect(mailer).to receive(:notify_out_of_storage).with(namespace: group, recipients: [owner.email],
            usage_values: {
              current_size: current_size.megabytes,
              limit: limit.megabytes,
              used_storage_percentage: used_storage_percentage
            })
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(group)

          expect(group.root_storage_statistics.reload.notification_level.to_sym).to eq(expected_level)
        end
      end

      where(:limit, :current_size, :used_storage_percentage, :last_notification_level, :expected_level) do
        100  | 70   | 70 | :storage_remaining | :caution
        100  | 85   | 85 | :storage_remaining | :warning
        100  | 95   | 95 | :storage_remaining | :danger
        100  | 77   | 77 | :storage_remaining | :caution
        1000 | 971  | 97 | :storage_remaining | :danger
        100  | 85   | 85 | :caution           | :warning
        100  | 95   | 95 | :warning           | :danger
        100  | 99   | 99 | :exceeded          | :danger
        100  | 94   | 94 | :danger            | :warning
        100  | 84   | 84 | :warning           | :caution
        8192 | 6144 | 75 | :storage_remaining | :caution
        5120 | 3840 | 75 | :storage_remaining | :caution
        5120 | 5118 | 99 | :warning           | :danger
      end

      with_them do
        it 'sends a storage limit notification when storage is running low' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: current_size)
          set_notification_level(last_notification_level)

          expect(mailer).to receive(:notify_limit_warning).with(namespace: group, recipients: [owner.email],
            usage_values: {
              current_size: current_size.megabytes,
              limit: limit.megabytes,
              used_storage_percentage: used_storage_percentage
            })
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(group)

          expect(group.root_storage_statistics.reload.notification_level.to_sym).to eq(expected_level)
        end
      end

      where(:limit, :current_size, :last_notification_level) do
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
          set_used_storage(group, megabytes: current_size)
          set_notification_level(last_notification_level)

          expect(mailer).not_to receive(:notify_out_of_storage)
          expect(mailer).not_to receive(:notify_limit_warning)

          service.execute(group)
        end
      end

      where(:limit, :current_size, :last_notification_level) do
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
          set_used_storage(group, megabytes: current_size)
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

        expect(mailer).to receive(:notify_out_of_storage).with(namespace: group, recipients: match_array(owner_emails),
          usage_values: {
            current_size: 200.megabytes,
            limit: 100.megabytes,
            used_storage_percentage: 200
          })
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

      where(:limit, :current_size, :last_notification_level) do
        100  | 70  | :caution
        100  | 85  | :warning
        100  | 95  | :danger
      end

      with_them do
        it 'does not send a storage limit notification for the same threshold twice' do
          set_storage_size_limit(group, megabytes: limit)
          set_used_storage(group, megabytes: current_size)
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
          set_storage_size_limit(namespace, megabytes: 100)
          set_used_storage(namespace, megabytes: 85)
          owner = namespace.owner

          expect(mailer).to receive(:notify_limit_warning).with(namespace: namespace, recipients: [owner.email],
            usage_values: {
              current_size: 85.megabytes,
              limit: 100.megabytes,
              used_storage_percentage: 85
            })
            .and_return(action_mailer)
          expect(action_mailer).to receive(:deliver_later)

          service.execute(namespace)
        end

        it 'sends an out of storage notification' do
          set_storage_size_limit(namespace, megabytes: 100)
          set_used_storage(namespace, megabytes: 550)
          owner = namespace.owner

          expect(mailer).to receive(:notify_out_of_storage).with(namespace: namespace, recipients: [owner.email],
            usage_values: {
              current_size: 550.megabytes,
              limit: 100.megabytes,
              used_storage_percentage: 550
            })
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
