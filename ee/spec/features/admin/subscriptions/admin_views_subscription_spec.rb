# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin views Subscription', :js do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  shared_examples 'an "Export license usage file" button' do
    it 'displays the Export License Usage File button' do
      expect(page).to have_link('Export license usage file', href: admin_license_usage_export_path(format: :csv))
    end
  end

  context 'with a cloud license' do
    let!(:license) { create_current_license(cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN) }

    context 'with a cloud license only' do
      before do
        visit(admin_subscription_path)
      end

      it 'displays the subscription details' do
        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content('Subscription details')
          expect(all("[data-testid='details-label']")[1]).to have_content('Plan:')
          expect(all("[data-testid='details-content']")[1]).to have_content('Ultimate')
        end
      end

      it 'succeeds to sync the subscription' do
        page.within(find('#content-body', match: :first)) do
          click_button('Sync subscription details')

          expect(page).to have_content('Your subscription details will sync shortly.')
        end
      end

      it 'fails to sync the subscription' do
        create_current_license(cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN, expires_at: nil)

        page.within(find('#content-body', match: :first)) do
          click_button('Sync subscription details')

          expect(page).to have_content('You can no longer sync your subscription details with GitLab. Get help for the most common connectivity issues by troubleshooting the activation code')
        end
      end

      it_behaves_like 'an "Export license usage file" button'
    end
  end

  context 'with license file' do
    let!(:license) { create_current_license(cloud_licensing_enabled: false, plan: License::ULTIMATE_PLAN) }

    before do
      visit(admin_subscription_path)
    end

    it_behaves_like 'an "Export license usage file" button'

    context 'when removing a license file' do
      before do
        accept_alert do
          click_on 'Remove license'
        end
      end

      it 'shows a message saying the license was correctly removed' do
        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content('The license was removed.')
        end
      end
    end

    context 'when activating another subscription' do
      before do
        page.within(find('[data-testid="subscription-details"]', match: :first)) do
          click_button('Activate cloud license')
        end
      end

      it 'shows the activation modal' do
        page.within(find('#subscription-activation-modal', match: :first)) do
          expect(page).to have_content('Activate subscription')
        end
      end

      it 'displays an error when the activation fails' do
        stub_request(:post, EE::SUBSCRIPTIONS_GRAPHQL_URL).to_return(status: 422, body: '', headers: {})

        page.within(find('#subscription-activation-modal', match: :first)) do
          fill_activation_form

          expect(page).to have_content('An error occurred while activating your subscription.')
        end
      end

      it 'displays a connectivity error' do
        stub_request(:post, EE::SUBSCRIPTIONS_GRAPHQL_URL)
          .to_return(status: 500, body: '', headers: {})

        page.within(find('#subscription-activation-modal', match: :first)) do
          fill_activation_form

          expect(page).to have_content('There is a connectivity issue.')
        end
      end
    end
  end

  context 'with no active subscription' do
    let_it_be(:license) { nil }

    before do
      allow(License).to receive(:current).and_return(license)

      visit(admin_subscription_path)
    end

    it 'displays a message signaling there is not active subscription' do
      page.within(find('#content-body', match: :first)) do
        expect(page).to have_content('You do not have an active subscription')
      end
    end

    it 'does not display the Export License Usage File button' do
      expect(page).not_to have_link('Export license usage file', href: admin_license_usage_export_path(format: :csv))
    end

    context 'when activating a new subscription' do
      before do
        license = create(:license, data: create(:gitlab_license, { cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN }).export)

        stub_request(:post, EE::SUBSCRIPTIONS_GRAPHQL_URL)
          .to_return(status: 200, body: {
            "data": {
              "cloudActivationActivate": {
                "licenseKey": license.data
              }
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        page.within(find('#content-body', match: :first)) do
          fill_activation_form
        end
      end

      it 'shows a successful activation message' do
        expect(page).to have_content('Your subscription was successfully activated.')
      end

      it 'shows the subscription details' do
        expect(page).to have_content('Subscription details')
      end

      it 'shows the appropriate license type' do
        page.within(find('[data-testid="subscription-cell-type"]', match: :first)) do
          expect(page).to have_content('Cloud license')
        end
      end
    end

    context 'when uploading a license file' do
      it 'shows a link to upload a license file' do
        page.within(find('#content-body', match: :first)) do
          expect(page).to have_link('Upload a license file', href: new_admin_license_path)
        end
      end
    end
  end

  private

  def fill_activation_form
    fill_in 'activationCode', with: 'fake-activation-code'
    check 'subscription-form-terms-check'
    click_button 'Activate'
  end
end
