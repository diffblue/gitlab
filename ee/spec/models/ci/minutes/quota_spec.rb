# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::Minutes::Quota do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) do
    create(:group, namespace_statistics: create(:namespace_statistics))
  end

  let(:quota) { described_class.new(namespace) }

  describe '#enabled?' do
    let(:project) { create(:project, namespace: namespace) }

    subject { quota.enabled? }

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

  describe '#monthly_minutes_report' do
    context 'when the quota is not enabled' do
      before do
        allow(quota).to receive(:enabled?).and_return(false)
        allow(namespace).to receive(:root?).and_return(namespace_eligible)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
      end

      context 'when the namespace is not eligible' do
        let(:namespace_eligible) { false }

        it 'returns not supported report with no usage' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 'Not supported'
          expect(report.used).to eq 0
          expect(report.status).to eq :disabled
        end
      end

      context 'when the namespace is eligible' do
        let(:namespace_eligible) { true }

        context 'when minutes are not used' do
          it 'returns unlimited report with no usage' do
            report = quota.monthly_minutes_report

            expect(report.limit).to eq 'Unlimited'
            expect(report.used).to eq 0
            expect(report.status).to eq :disabled
          end
        end

        context 'when minutes are used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 20.minutes
          end

          it 'returns unlimited report with usage' do
            report = quota.monthly_minutes_report

            expect(report.limit).to eq 'Unlimited'
            expect(report.used).to eq 20
            expect(report.status).to eq :disabled
          end
        end
      end
    end

    context 'when limited' do
      before do
        allow(quota).to receive(:enabled?).and_return(true)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 100
      end

      context 'when minutes are not all used' do
        before do
          namespace.namespace_statistics.shared_runners_seconds = 30.minutes
        end

        it 'returns report with under quota' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 100
          expect(report.used).to eq 30
          expect(report.status).to eq :under_quota
        end
      end

      context 'when minutes are all used' do
        before do
          namespace.namespace_statistics.shared_runners_seconds = 101.minutes
        end

        it 'returns report with over quota' do
          report = quota.monthly_minutes_report

          expect(report.limit).to eq 100
          expect(report.used).to eq 101
          expect(report.status).to eq :over_quota
        end
      end
    end
  end

  describe '#purchased_minutes_report' do
    context 'when limit enabled' do
      before do
        allow(quota).to receive(:enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 200
      end

      context 'when extra minutes have been purchased' do
        before do
          namespace.extra_shared_runners_minutes_limit = 100
        end

        context 'when all monthly minutes are used and some puarchased minutes are used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 250.minutes
          end

          it 'returns report with under quota' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 50
            expect(report.status).to eq :under_quota
          end
        end

        context 'when all monthly and all puarchased minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 301.minutes
          end

          it 'returns report with over quota' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 101
            expect(report.status).to eq :over_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 190.minutes
          end

          it 'returns report with no usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end
      end

      context 'when no extra minutes have been purchased' do
        before do
          namespace.extra_shared_runners_minutes_limit = nil
        end

        context 'when all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 201.minutes
          end

          it 'returns report without usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            namespace.namespace_statistics.shared_runners_seconds = 190.minutes
          end

          it 'returns report with no usage' do
            report = quota.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end
      end
    end
  end

  describe '#monthly_percent_used' do
    subject { quota.monthly_percent_used }

    where(:limit_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :title) do
      false | 200 | 0   | 40  | 0   | 'limit not enabled'
      true  | 200 | 0   | 0   | 0   | 'monthly limit set and no usage'
      true  | 200 | 0   | 40  | 20  | 'monthly limit set and usage lower than 100%'
      true  | 200 | 0   | 200 | 100 | 'monthly limit set and usage at 100%'
      true  | 200 | 0   | 210 | 105 | 'monthly limit set and usage above 100%'
      true  | 0   | 0   | 0   | 0   | 'monthly limit not set and no usage'
      true  | 0   | 0   | 40  | 0   | 'monthly limit not set and some usage'
      true  | 200 | 100 | 0   | 0   | 'monthly and purchased limits set and no usage'
      true  | 200 | 100 | 40  | 20  | 'monthly and purchased limits set and low usage'
      true  | 200 | 100 | 210 | 100 | 'usage capped to 100% and overflows into purchased minutes'
    end

    with_them do
      before do
        allow(quota).to receive(:enabled?).and_return(limit_enabled)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = monthly_limit
        namespace.extra_shared_runners_minutes_limit = purchased_limit
        namespace.namespace_statistics.shared_runners_seconds = minutes_used.minutes
      end

      it 'returns the percentage' do
        is_expected.to eq result
      end
    end
  end

  describe '#purchased_percent_used' do
    subject { quota.purchased_percent_used }

    where(:limit_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :title) do
      false | 0   | 0   | 40  | 0   | 'limit not enabled'
      true  | 0   | 200 | 40  | 20  | 'monthly limit not set and purchased limit set and low usage'
      true  | 200 | 0   | 40  | 0   | 'monthly limit set and purchased limit not set and usage below monthly'
      true  | 200 | 0   | 240 | 0   | 'monthly limit set and purchased limit not set and usage above monthly'
      true  | 200 | 200 | 0   | 0   | 'monthly and purchased limits set and no usage'
      true  | 200 | 200 | 40  | 0   | 'monthly and purchased limits set and usage below monthly'
      true  | 200 | 200 | 200 | 0   | 'monthly and purchased limits set and monthly minutes maxed out'
      true  | 200 | 200 | 300 | 50  | 'monthly and purchased limits set and some purchased minutes used'
      true  | 200 | 200 | 400 | 100 | 'monthly and purchased limits set and all minutes used'
      true  | 200 | 200 | 430 | 115 | 'monthly and purchased limits set and usage beyond all limits'
    end

    with_them do
      before do
        allow(quota).to receive(:enabled?).and_return(limit_enabled)
        namespace.shared_runners_minutes_limit = monthly_limit
        namespace.extra_shared_runners_minutes_limit = purchased_limit
        namespace.namespace_statistics.shared_runners_seconds = minutes_used.minutes
      end

      it 'returns the percentage' do
        is_expected.to eq result
      end
    end
  end

  describe '#minutes_used_up?' do
    subject { quota.minutes_used_up? }

    where(:limit_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :title) do
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
      before do
        allow(quota).to receive(:enabled?).and_return(limit_enabled)
        namespace.shared_runners_minutes_limit = monthly_limit
        namespace.extra_shared_runners_minutes_limit = purchased_limit
        namespace.namespace_statistics.shared_runners_seconds = minutes_used.minutes
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#total_minutes' do
    subject { quota.total_minutes }

    where(:namespace_monthly_limit, :application_monthly_limit, :purchased_minutes, :result) do
      20  | 100 | 30 | 50
      nil | 100 | 30 | 130
      20  | 100 | 0  | 20
      0   | 0   | 30 | 30
      nil | 0   | 30 | 30
    end

    with_them do
      before do
        namespace.shared_runners_minutes_limit = namespace_monthly_limit
        allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(application_monthly_limit)
        allow(namespace).to receive(:extra_shared_runners_minutes_limit).and_return(purchased_minutes)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#total_minutes_used' do
    subject { quota.total_minutes_used }

    where(:expected_seconds, :expected_minutes) do
      nil | 0
      0   | 0
      59  | 0
      60  | 1
      122 | 2
    end

    with_them do
      before do
        allow(namespace).to receive(:shared_runners_seconds).and_return(expected_seconds)
      end

      it { is_expected.to eq(expected_minutes) }
    end
  end

  describe '#percent_total_minutes_remaining' do
    subject { quota.percent_total_minutes_remaining }

    where(:total_minutes_used, :monthly_minutes, :purchased_minutes, :result) do
      0   | 0   | 0 | 0
      10  | 0   | 0 | 0
      0   | 70  | 30 | 100
      60  | 70  | 30 | 40
      100 | 70  | 30 | 0
      120 | 70  | 30 | 0
    end

    with_them do
      before do
        allow(namespace).to receive(:shared_runners_seconds).and_return(total_minutes_used * 60)
        allow(namespace).to receive(:shared_runners_minutes_limit).and_return(monthly_minutes)
        allow(namespace).to receive(:extra_shared_runners_minutes_limit).and_return(purchased_minutes)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#any_project_enabled?' do
    let_it_be(:project) { create(:project, namespace: namespace) }

    context 'when namespace has any project with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'returns true' do
        expect(quota.any_project_enabled?).to be_truthy
      end
    end

    context 'when namespace has no projects with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it 'returns false' do
        expect(quota.any_project_enabled?).to be_falsey
      end
    end

    it 'does not trigger additional queries when called multiple times' do
      # memoizes the result
      quota.any_project_enabled?

      # count
      actual = ActiveRecord::QueryRecorder.new do
        quota.any_project_enabled?
      end

      expect(actual.count).to eq(0)
    end
  end

  describe '#display_shared_runners_data?' do
    let_it_be(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

    subject { quota.display_shared_runners_data? }

    context 'when the namespace is root and it has a project with shared runners enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when the namespace is not root' do
      let(:namespace) { create(:group, :nested) }

      it { is_expected.to be_falsey }
    end

    context 'when the namespaces has no project with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#display_minutes_available_data?' do
    let_it_be(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

    subject { quota.display_minutes_available_data? }

    context 'when the namespace is root and it has a project with shared runners enabled' do
      context 'when there is a minutes limit' do
        before do
          namespace.update!(shared_runners_minutes_limit: 200)
        end

        it { is_expected.to be_truthy }
      end

      context 'when there is no minutes limit' do
        before do
          namespace.update!(shared_runners_minutes_limit: 0)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when the namespace is not root' do
      let(:namespace) { create(:group, :nested) }

      it { is_expected.to be_falsey }
    end

    context 'when the namespaces has no project with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
