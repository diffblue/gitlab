# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::UsagePresenter do
  include ::Ci::MinutesHelpers

  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) do
    create(:group, namespace_statistics: create(:namespace_statistics))
  end

  let(:usage) { Ci::Minutes::Usage.new(namespace) }

  subject(:presenter) { described_class.new(usage) }

  describe '#monthly_minutes_report' do
    context 'when the usage is not enabled' do
      before do
        allow(usage).to receive(:quota_enabled?).and_return(false)
        allow(namespace).to receive(:root?).and_return(namespace_eligible)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
      end

      context 'when the namespace is not eligible' do
        let(:namespace_eligible) { false }

        it 'returns not supported report with no usage' do
          report = presenter.monthly_minutes_report

          expect(report.limit).to eq 'Not supported'
          expect(report.used).to eq 0
          expect(report.status).to eq :disabled
        end
      end

      context 'when the namespace is eligible' do
        let(:namespace_eligible) { true }

        context 'when minutes are not used' do
          it 'returns unlimited report with no usage' do
            report = presenter.monthly_minutes_report

            expect(report.limit).to eq 'Unlimited'
            expect(report.used).to eq 0
            expect(report.status).to eq :disabled
          end
        end

        context 'when minutes are used' do
          before do
            set_ci_minutes_used(namespace, 20)
          end

          it 'returns unlimited report with usage' do
            report = presenter.monthly_minutes_report

            expect(report.limit).to eq 'Unlimited'
            expect(report.used).to eq 20
            expect(report.status).to eq :disabled
          end
        end
      end
    end

    context 'when limited' do
      before do
        allow(presenter).to receive(:quota_enabled?).and_return(true)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 100
      end

      context 'when minutes are not all used' do
        before do
          set_ci_minutes_used(namespace, 30)
        end

        it 'returns report with under usage' do
          report = presenter.monthly_minutes_report

          expect(report.limit).to eq 100
          expect(report.used).to eq 30
          expect(report.status).to eq :under_quota
        end
      end

      context 'when minutes are all used' do
        before do
          set_ci_minutes_used(namespace, 101)
        end

        it 'returns report with over quota' do
          report = presenter.monthly_minutes_report

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
        allow(usage).to receive(:quota_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = 200
      end

      context 'when extra minutes have been purchased' do
        before do
          namespace.extra_shared_runners_minutes_limit = 100
        end

        context 'when all monthly minutes are used and some puarchased minutes are used' do
          before do
            set_ci_minutes_used(namespace, 250)
          end

          it 'returns report with under quota' do
            report = presenter.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 50
            expect(report.status).to eq :under_quota
          end
        end

        context 'when all monthly and all puarchased minutes have been used' do
          before do
            set_ci_minutes_used(namespace, 301)
          end

          it 'returns report with over quota' do
            report = presenter.purchased_minutes_report

            expect(report.limit).to eq 100
            expect(report.used).to eq 101
            expect(report.status).to eq :over_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            set_ci_minutes_used(namespace, 190)
          end

          it 'returns report with no usage' do
            report = presenter.purchased_minutes_report

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
            set_ci_minutes_used(namespace, 201)
          end

          it 'returns report without usage' do
            report = presenter.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end

        context 'when not all monthly minutes have been used' do
          before do
            set_ci_minutes_used(namespace, 190)
          end

          it 'returns report with no usage' do
            report = presenter.purchased_minutes_report

            expect(report.limit).to eq 0
            expect(report.used).to eq 0
            expect(report.status).to eq :under_quota
          end
        end
      end
    end
  end

  describe '#monthly_percent_used' do
    subject { presenter.monthly_percent_used }

    where(:quota_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :case_name) do
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
        allow(usage).to receive(:quota_enabled?).and_return(quota_enabled)
        allow(namespace).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
        namespace.shared_runners_minutes_limit = monthly_limit
        namespace.extra_shared_runners_minutes_limit = purchased_limit
        set_ci_minutes_used(namespace, minutes_used)
      end

      it 'returns the percentage' do
        is_expected.to eq result
      end
    end
  end

  describe '#purchased_percent_used' do
    subject { presenter.purchased_percent_used }

    where(:quota_enabled, :monthly_limit, :purchased_limit, :minutes_used, :result, :case_name) do
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
        allow(usage).to receive(:quota_enabled?).and_return(quota_enabled)
        namespace.shared_runners_minutes_limit = monthly_limit
        namespace.extra_shared_runners_minutes_limit = purchased_limit
        set_ci_minutes_used(namespace, minutes_used)
      end

      it 'returns the percentage' do
        is_expected.to eq result
      end
    end
  end

  describe '#any_project_enabled?' do
    let_it_be(:project) { create(:project, namespace: namespace) }

    context 'when namespace has any project with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'returns true' do
        expect(presenter.any_project_enabled?).to be_truthy
      end
    end

    context 'when namespace has no projects with shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it 'returns false' do
        expect(presenter.any_project_enabled?).to be_falsey
      end
    end

    it 'does not trigger additional queries when called multiple times' do
      # memoizes the result
      presenter.any_project_enabled?

      # count
      actual = ActiveRecord::QueryRecorder.new do
        presenter.any_project_enabled?
      end

      expect(actual.count).to eq(0)
    end
  end

  describe '#display_shared_runners_data?' do
    let_it_be(:project) { create(:project, namespace: namespace, shared_runners_enabled: true) }

    subject { presenter.send(:display_shared_runners_data?) }

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
end
