# frozen_string_literal: true

RSpec.shared_examples 'manual renewal banner' do |path_to_visit:|
  shared_examples 'a visible manual renewal banner' do
    it 'displays a banner' do
      expect(page).to have_selector('[data-testid="manual-renewal-banner"]')
    end
  end

  shared_examples 'a hidden manual renewal banner' do
    it 'does not display a banner' do
      expect(page).not_to have_selector('[data-testid="manual-renewal-banner"]')
    end
  end

  describe 'manual renewal banner', :js do
    let_it_be(:reminder_days) { Gitlab::ManualRenewalBanner::REMINDER_DAYS }

    before do
      create_current_license(
        cloud_licensing_enabled: true,
        offline_cloud_licensing_enabled: true,
        expires_at: expires_at
      )

      allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { should_check_namespace_plan? }

      visit(send(path_to_visit))
    end

    context 'when on Gitlab.com' do
      let(:expires_at) { 1.month.from_now.to_date }
      let(:should_check_namespace_plan?) { true }

      it_behaves_like 'a hidden manual renewal banner'
    end

    context 'when on self-managed' do
      let(:should_check_namespace_plan?) { false }

      context 'when subscription is expiring' do
        context 'within notification window' do
          let(:expires_at) { Date.today + reminder_days }

          it_behaves_like 'a visible manual renewal banner'
        end

        context 'outside of notification window' do
          let(:expires_at) { Date.tomorrow + reminder_days }

          it_behaves_like 'a hidden manual renewal banner'
        end
      end

      context 'when subscription is expired' do
        let(:expires_at) { Date.today }

        it_behaves_like 'a visible manual renewal banner'
      end

      context 'when subscription is not expiring/expired yet' do
        let(:expires_at) { 1.month.from_now.to_date }

        it_behaves_like 'a hidden manual renewal banner'
      end
    end
  end
end
