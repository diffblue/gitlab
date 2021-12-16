# frozen_string_literal: true

RSpec.shared_examples 'manual quarterly co-term banner' do |path_to_visit:|
  shared_examples 'a visible dismissible manual quarterly co-term banner' do
    context 'when dismissed' do
      before do
        page.within(find('[data-testid="close-manual-quarterly-co-term-banner"]', match: :first)) do
          click_button 'Dismiss'
        end
      end

      it_behaves_like 'a hidden manual quarterly co-term banner'

      context 'when visiting again' do
        before do
          visit current_path
        end

        it 'displays a banner' do
          expect(page).to have_selector('[data-testid="close-manual-quarterly-co-term-banner"]')
        end
      end
    end
  end

  shared_examples 'a hidden manual quarterly co-term banner' do
    it 'does not display a banner' do
      expect(page).not_to have_selector('[data-testid="close-manual-quarterly-co-term-banner"]')
    end
  end

  describe 'manual quarterly co-term banner', :js do
    let_it_be(:reminder_days) { Gitlab::ManualQuarterlyCoTermBanner::REMINDER_DAYS }

    before do
      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { should_check_namespace_plan? }

      create(:upcoming_reconciliation, type, next_reconciliation_date: reconciliation_date)

      visit(send(path_to_visit))
    end

    context 'when on Gitlab.com' do
      let(:reconciliation_date) { Date.current }
      let(:should_check_namespace_plan?) { true }
      let(:type) { :saas }

      it_behaves_like 'a hidden manual quarterly co-term banner'
    end

    context 'when on self-managed' do
      let(:should_check_namespace_plan?) { false }
      let(:type) { :self_managed }

      context 'when reconciliation is upcoming' do
        context 'within notification window' do
          let(:reconciliation_date) { Date.current + reminder_days }

          it_behaves_like 'a visible dismissible manual quarterly co-term banner'
        end

        context 'outside of notification window' do
          let(:reconciliation_date) { Date.tomorrow + reminder_days }

          it_behaves_like 'a hidden manual quarterly co-term banner'
        end
      end

      context 'when reconciliation date was passed' do
        let(:reconciliation_date) { Date.current }

        it_behaves_like 'a visible dismissible manual quarterly co-term banner'
      end

      context 'when reconciliation date is outside of the notification window' do
        let(:reconciliation_date) { 1.month.from_now.to_date }

        it_behaves_like 'a hidden manual quarterly co-term banner'
      end
    end
  end
end
