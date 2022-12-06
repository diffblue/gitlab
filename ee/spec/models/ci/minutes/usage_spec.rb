# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::Minutes::Usage do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) do
    create(:group, namespace_statistics: create(:namespace_statistics))
  end

  let(:usage) { described_class.new(namespace) }

  describe '#enabled?' do
    let(:project) { create(:project, namespace: namespace) }

    subject { usage.quota_enabled? }

    context 'when namespace is root' do
      context 'when namespace has any project with shared runners enabled' do
        before do
          project.update!(shared_runners_enabled: true)
        end

        context 'when namespace has minutes limit' do
          before do
            allow(namespace).to receive(:shared_runners_minutes_limit).and_return(1000)
          end

          it { is_expected.to be_truthy }
        end

        context 'when namespace has unlimited minutes' do
          before do
            allow(namespace).to receive(:shared_runners_minutes_limit).and_return(0)
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when namespace has a limit but does not have projects with shared runners enabled' do
        before do
          project.update!(shared_runners_enabled: false)
          allow(namespace).to receive(:shared_runners_minutes_limit).and_return(1000)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when namespace is not root' do
      let(:parent) { create(:group) }
      let!(:namespace) { create(:group, parent: parent) }
      let!(:project) { create(:project, namespace: namespace, shared_runners_enabled: false) }

      before do
        namespace.update!(parent: parent)
        project.update!(shared_runners_enabled: false)
        allow(namespace).to receive(:shared_runners_minutes_limit).and_return(1000)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#minutes_used_up?' do
    subject { usage.minutes_used_up? }

    where(:limit_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :case_name) do
      false | 0   | 0   | 40  | false | 'limit not enabled'
      true  | 0   | 200 | 40  | false | 'monthly limit not set and purchased limit set and low usage'
      true  | 200 | 0   | 40  | false | 'monthly limit set and purchased limit not set and usage below monthly'
      true  | 200 | 0   | 240 | true  | 'monthly limit set and purchased limit not set and usage above monthly'
      true  | 200 | 200 | 0   | false | 'monthly and purchased limits set and no usage'
      true  | 200 | 200 | 40  | false | 'monthly and purchased limits set and usage below monthly'
      true  | 200 | 200 | 200 | false | 'monthly and purchased limits set and monthly minutes maxed out'
      true  | 200 | 200 | 300 | false | 'monthly and purchased limits set and some purchased minutes used'
      true  | 200 | 200 | 400 | true  | 'monthly and purchased limits set and all minutes used'
      true  | 200 | 200 | 430 | true  | 'monthly and purchased limits set and usage beyond all limits'
    end

    with_them do
      let(:namespace) do
        create(
          :namespace,
          :with_ci_minutes,
          ci_minutes_limit: monthly_limit,
          ci_minutes_used: minutes_used
        )
      end

      before do
        allow(usage).to receive(:enabled?).and_return(limit_enabled)
        namespace.extra_shared_runners_minutes_limit = purchased_limit
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#total_minutes_used' do
    let(:namespace) { create(:namespace, :with_ci_minutes, ci_minutes_used: minutes_used) }

    subject { usage.total_minutes_used }

    where(:minutes_used, :expected_minutes) do
      nil | 0
      0   | 0
      0.9 | 0
      1.1 | 1
      2.1 | 2
    end

    with_them do
      it { is_expected.to eq(expected_minutes) }
    end
  end

  describe '#percent_total_minutes_remaining' do
    subject { usage.percent_total_minutes_remaining }

    where(:total_minutes_used, :monthly_minutes, :purchased_minutes, :result) do
      0   | 0   | 0 | 0
      10  | 0   | 0 | 0
      0   | 70  | 30 | 100
      60  | 70  | 30 | 40
      100 | 70  | 30 | 0
      120 | 70  | 30 | 0
    end

    with_them do
      let(:namespace) do
        create(
          :namespace,
          :with_ci_minutes,
          ci_minutes_used: total_minutes_used,
          ci_minutes_limit: monthly_minutes
        )
      end

      before do
        allow(namespace).to receive(:extra_shared_runners_minutes_limit).and_return(purchased_minutes)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#monthly_minutes_used_up?' do
    subject { usage.monthly_minutes_used_up? }

    context 'when usage is enabled' do
      let(:total_minutes) { 1000 }
      let(:namespace) do
        create(
          :namespace,
          :with_ci_minutes,
          ci_minutes_used: total_minutes_used,
          ci_minutes_limit: total_minutes
        )
      end

      context 'when monthly minutes usage greater than monthly minutes used' do
        let(:total_minutes_used) { total_minutes - 1 }

        it { is_expected.to be_falsey }
      end

      context 'when monthly minutes usage less than monthly minutes used' do
        let(:total_minutes_used) { total_minutes + 1 }

        it { is_expected.to be_truthy }
      end

      context 'when monthly minutes usage equals monthly minutes used' do
        let(:total_minutes_used) { total_minutes }

        it { is_expected.to be_truthy }
      end
    end

    context 'when usage is disabled' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit).and_return(0)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#purchased_minutes_used_up?' do
    subject { usage.purchased_minutes_used_up? }

    context 'when usage is enabled' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit).and_return(1000)
      end

      context 'when no minutes are purchased' do
        let(:purchased_minutes) { 0 }

        before do
          allow(namespace).to receive(:extra_shared_runners_minutes_limit).and_return(purchased_minutes)
        end

        it { is_expected.to be_falsey }
      end

      context 'when minutes are purchased' do
        where(:purchased_minutes, :monthly_minutes, :total_minutes_used, :result) do
          1000   | 1000   | 2001 | true
          1000   | 1000   | 2000 | true
          1000   | 1000   | 1999 | false
        end

        with_them do
          let(:namespace) do
            create(
              :namespace,
              :with_ci_minutes,
              ci_minutes_limit: monthly_minutes,
              ci_minutes_used: total_minutes_used
            )
          end

          before do
            allow(namespace).to receive(:extra_shared_runners_minutes_limit).and_return(purchased_minutes)
          end

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'when usage is disabled' do
      before do
        allow(namespace).to receive(:shared_runners_minutes_limit).and_return(0)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#reset_date' do
    subject(:reset_date) { usage.reset_date }

    around do |example|
      travel_to(Date.new(2021, 07, 14)) { example.run }
    end

    let(:namespace) do
      create(:namespace, :with_ci_minutes)
    end

    it 'corresponds to the beginning of the current month' do
      expect(reset_date).to eq(Date.new(2021, 07, 1))
    end
  end
end
