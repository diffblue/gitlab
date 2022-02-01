# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionPresenter, :saas do
  using RSpec::Parameterized::TableSyntax

  let(:subscription) { create(:gitlab_subscription) }
  let(:presenter) { described_class.new(subscription) }

  describe '#plan' do
    subject { presenter.plan }

    it { is_expected.to eq('ultimate') }
  end

  describe '#notify_admins?' do
    subject { presenter.notify_admins? }

    where(:remaining_days_count, :expected_result) do
      nil  | false
      0    | true
      described_class::RENEWAL_ALLOWED_PERIOD_DAYS - 1.day   | true
      described_class::RENEWAL_ALLOWED_PERIOD_DAYS           | true
      described_class::RENEWAL_ALLOWED_PERIOD_DAYS + 1.day   | false
    end

    with_them do
      before do
        allow(presenter).to receive(:remaining_days).and_return(remaining_days_count)
      end

      it { expect(subject).to be(expected_result) }
    end
  end

  describe '#notify_users?' do
    subject { presenter.notify_users? }

    it { is_expected.to be false }
  end

  describe '#block_changes_at' do
    subject { presenter.block_changes_at }

    it { is_expected.to eq(subscription.end_date + 14.days) }

    context 'when end_date is nil' do
      it 'is nil' do
        allow(subscription).to receive(:end_date).and_return(nil)

        expect(subject).to be nil
      end
    end
  end

  describe '#block_changes?' do
    subject { presenter.block_changes? }

    let(:today) { Time.utc(2020, 3, 7, 10) }

    before do
      allow(subscription).to receive(:end_date).and_return(end_date)
    end

    context 'end_date is nil' do
      let(:end_date) { nil }

      it { is_expected.to be false }
    end

    context 'is not expired' do
      let(:end_date) { today + 1.day }

      it 'is false' do
        travel_to(today) do
          expect(subject).to be false
        end
      end
    end

    context 'is expired' do
      context 'is not past grace period' do
        let(:end_date) { today - 13.days }

        it 'is false' do
          travel_to(today) do
            expect(subject).to be false
          end
        end
      end

      context 'is past grace period' do
        let(:end_date) { today - 15.days }

        it 'is true' do
          travel_to(today) do
            expect(subject).to be true
          end
        end
      end
    end
  end

  describe '#will_block_changes?' do
    subject { presenter.will_block_changes? }

    context 'when end_date exists' do
      it { is_expected.to be true }
    end

    context 'when end_date does not exist' do
      it 'is false' do
        allow(subscription).to receive(:end_date).and_return(nil)

        expect(subject).to be false
      end
    end
  end

  describe '#remaining_days' do
    subject { presenter.remaining_days }

    let(:today) { Time.utc(2020, 3, 7, 10) }

    it 'is nil when end_date is nil' do
      allow(subscription).to receive(:end_date).and_return(nil)

      expect(subject).to be nil
    end

    it 'returns the number of days between end_date and today' do
      allow(subscription).to receive(:end_date).and_return(Time.utc(2020, 3, 9, 10).to_date)

      travel_to(today) do
        expect(subject).to eq(2)
      end
    end

    it 'is 0 if expired' do
      allow(subscription).to receive(:end_date).and_return(Time.utc(2020, 3, 1, 10).to_date)

      travel_to(today) do
        expect(subject).to eq(0)
      end
    end
  end
end
