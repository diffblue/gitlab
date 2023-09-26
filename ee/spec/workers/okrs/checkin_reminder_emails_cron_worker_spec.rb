# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Okrs::CheckinReminderEmailsCronWorker, feature_category: :team_planning do
  let(:cron) { described_class.new }

  describe "#perform" do
    before do
      allow(cron).to receive(:frequencies).and_return(['weekly'])
    end

    let(:mail_instance) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:objective) { create(:work_item, :objective, project: project) }
    let_it_be(:objective_progress) { create(:progress, work_item: objective, reminder_frequency: 'weekly') }
    let!(:key_result) { create(:work_item, :key_result, project: project) }
    let!(:parent_link) { create(:parent_link, work_item_parent: objective, work_item: key_result) }
    let!(:key_result_progress) { create(:progress, work_item: key_result) }

    it 'does nothing if the feature flag is disabled' do
      stub_feature_flags(okr_checkin_reminders: false)

      expect(Notify).not_to receive(:okr_checkin_reminder_notification)

      key_result.assignees = [user1]
      cron.perform
    end

    it 'sends one notification if there is one assignee' do
      expect(Notify).to receive(:okr_checkin_reminder_notification).once.and_call_original

      key_result.assignees = [user1]
      cron.perform
    end

    it 'sends multiple notifications if there are multiple assignees' do
      expect(Notify).to receive(:okr_checkin_reminder_notification).twice.and_call_original

      key_result.assignees = [user1, user2]
      cron.perform
    end

    it 'updates the last_reminder_sent_at timestamp on the key_result', :freeze_time do
      key_result.assignees = [user1, user2]

      expect { cron.perform }.to change { key_result.reload.progress.last_reminder_sent_at }.from(nil).to(Time.zone.now)
    end
  end

  describe "#frequencies" do
    let(:cron) { described_class.new(date: date) }

    subject { cron.frequencies }

    using RSpec::Parameterized::TableSyntax

    where(:date, :expected_response) do
      DateTime.parse('2023-08-01') | %w[weekly twice_monthly monthly]
      DateTime.parse('2023-08-02') | %w[]
      DateTime.parse('2023-08-03') | %w[]
      DateTime.parse('2023-08-04') | %w[]
      DateTime.parse('2023-08-05') | %w[]
      DateTime.parse('2023-08-06') | %w[]
      DateTime.parse('2023-08-07') | %w[]
      DateTime.parse('2023-08-08') | %w[weekly]
      DateTime.parse('2023-08-09') | %w[]
      DateTime.parse('2023-08-14') | %w[]
      DateTime.parse('2023-08-15') | %w[weekly twice_monthly]
      DateTime.parse('2023-08-16') | %w[]
      DateTime.parse('2023-08-21') | %w[]
      DateTime.parse('2023-08-22') | %w[weekly]
      DateTime.parse('2023-08-23') | %w[]
      DateTime.parse('2023-08-29') | %w[weekly]
    end

    with_them do
      it { is_expected.to eq(expected_response) }
    end
  end
end
