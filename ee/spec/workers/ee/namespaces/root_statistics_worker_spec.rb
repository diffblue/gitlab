# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::RootStatisticsWorker, '#perform', :saas do
  include NamespaceStorageHelpers

  let_it_be(:group, refind: true) { create(:group_with_plan, :with_aggregation_schedule, plan: :ultimate_plan) }
  let_it_be(:project, refind: true) { create(:project, namespace: group) }
  let_it_be(:owner) { create(:user) }

  let(:mailer) { class_double(::Emails::NamespaceStorageUsageMailer).as_stubbed_const }
  let(:action_mailer) { instance_double(ActionMailer::MessageDelivery) }

  subject(:worker) { described_class.new }

  before_all do
    group.add_owner(owner)
  end

  context 'when storage limits are enforced for the namespace' do
    before do
      allow(::EE::Gitlab::Namespaces::Storage::Enforcement).to receive(:enforce_limit?).with(group).and_return(true)
    end

    context 'when the namespace is running low on storage' do
      it 'sends a notification email' do
        set_storage_size_limit(group, megabytes: 10)
        project.statistics.update!(repository_size: 9.megabytes)

        expect(mailer).to receive(:notify_limit_warning).with(group, [owner.email], 10, 1.megabyte)
          .and_return(action_mailer)
        expect(action_mailer).to receive(:deliver_later)

        worker.perform(group.id)
      end
    end

    context 'without a namespace' do
      it 'does not send an email notification' do
        expect(mailer).not_to receive(:notify_limit_warning)
        expect(mailer).not_to receive(:notify_out_of_storage)

        worker.perform(non_existing_record_id)
      end
    end

    context 'without an aggregation scheduled' do
      before do
        group.aggregation_schedule.destroy!
      end

      it 'does not send an email notification' do
        expect(mailer).not_to receive(:notify_limit_warning)
        expect(mailer).not_to receive(:notify_out_of_storage)

        worker.perform(group.id)
      end
    end

    context 'when something goes wrong when updating' do
      before do
        allow_next_instance_of(Namespaces::StatisticsRefresherService) do |instance|
          allow(instance).to receive(:execute)
                .and_raise(Namespaces::StatisticsRefresherService::RefresherError, 'error')
        end
      end

      it 'does not send an email notification' do
        expect(mailer).not_to receive(:notify_limit_warning)
        expect(mailer).not_to receive(:notify_out_of_storage)

        worker.perform(group.id)
      end
    end
  end

  context 'when storage limits are not enforced for the namespace' do
    before do
      allow(::EE::Gitlab::Namespaces::Storage::Enforcement).to receive(:enforce_limit?).with(group).and_return(false)
    end

    context 'when the namespace is running low on storage' do
      it 'does not send a notification email' do
        set_storage_size_limit(group, megabytes: 10)
        project.statistics.update!(repository_size: 9.megabytes)

        expect(mailer).not_to receive(:notify_limit_warning)
        expect(mailer).not_to receive(:notify_out_of_storage)

        worker.perform(group.id)
      end
    end
  end
end
