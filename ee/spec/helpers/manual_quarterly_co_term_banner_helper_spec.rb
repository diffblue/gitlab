# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ManualQuarterlyCoTermBannerHelper do
  describe '#manual_quarterly_co_term_banner' do
    subject(:manual_quarterly_co_term_banner) { helper.manual_quarterly_co_term_banner }

    let_it_be(:current_user) { create(:admin) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    context 'when current user is empty' do
      let(:current_user) { nil }

      it 'does not return a banner payload' do
        expect(manual_quarterly_co_term_banner).to eq(nil)
      end
    end

    context 'when current user cannot admin all resources' do
      it 'does not return a banner payload' do
        expect(manual_quarterly_co_term_banner).to eq(nil)
      end
    end

    context 'when current user can admin all resources' do
      before do
        allow(current_user).to receive(:can_admin_all_resources?).and_return(true)

        allow_next_instance_of(Gitlab::ManualQuarterlyCoTermBanner) do |banner|
          allow(banner).to receive(:display?).and_return(display_banner)
        end
      end

      context 'when no banner instance is returned' do
        let(:display_banner) { false }

        it 'does not return a banner payload' do
          aggregate_failures do
            expect(manual_quarterly_co_term_banner).to be_an_instance_of(Gitlab::ManualQuarterlyCoTermBanner)
            expect(manual_quarterly_co_term_banner.subject).to eq(nil)
          end
        end
      end

      context 'when a banner instance is returned' do
        let(:display_banner) { true }

        let(:upcoming_reconciliation) do
          create(:upcoming_reconciliation, :self_managed, next_reconciliation_date: next_reconciliation_date)
        end

        before do
          allow(GitlabSubscriptions::UpcomingReconciliation).to receive(:next).and_return(upcoming_reconciliation)
        end

        context 'when reconciliation is overdue' do
          let!(:next_reconciliation_date) { Date.yesterday }

          it 'returns a banner payload' do
            aggregate_failures do
              expect(manual_quarterly_co_term_banner).to be_an_instance_of(Gitlab::ManualQuarterlyCoTermBanner)
              expect(manual_quarterly_co_term_banner.body).to include('GitLab must now reconcile your subscription')
              expect(manual_quarterly_co_term_banner.display_error_version?).to eq(true)
            end
          end
        end

        context 'when reconciliation is upcoming' do
          let(:next_reconciliation_date) { Date.current + 60.days }

          it 'returns a banner payload' do
            aggregate_failures do
              expect(manual_quarterly_co_term_banner).to be_an_instance_of(Gitlab::ManualQuarterlyCoTermBanner)
              expect(manual_quarterly_co_term_banner.body).to include('GitLab must reconcile your subscription')
              expect(manual_quarterly_co_term_banner.display_error_version?).to eq(false)
            end
          end
        end
      end
    end
  end
end
