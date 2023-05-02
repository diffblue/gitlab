# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin views Subscription', :js, feature_category: :subscription_management do
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:admin) { create(:admin) }
  let(:graphql_url) { ::Gitlab::Routing.url_helpers.subscription_portal_graphql_url }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  shared_examples 'an "Export license usage file" button' do
    it 'displays the Export License Usage File button' do
      expect(page).to have_link('Export license usage file', href: admin_license_usage_export_path(format: :csv))
    end
  end

  shared_examples 'license removal' do
    context 'when removing a license file' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'shows a message saying the license was correctly removed' do
        visit(admin_subscription_path)

        click_button('Remove license')

        within_modal do
          expect(page).not_to have_content('This change will remove ALL Premium and Ultimate features for ALL SaaS customers and make tests start failing.')
          click_button('Remove license')
        end

        page.within(find('#content-body', match: :first)) do
          expect(page).to have_content('The license was removed.')
        end
      end
    end

    context 'when the instance is SaaS' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'shows a message with a warning affecting all customers' do
        visit(admin_subscription_path)

        click_button 'Remove license'

        within_modal do
          expect(page).to have_content('This change will remove ALL Premium and Ultimate features for ALL SaaS customers and make tests start failing.')
        end
      end
    end
  end

  shared_examples 'no active license' do
    it 'displays a message signaling there is not active subscription' do
      page.within(find('#content-body', match: :first)) do
        expect(page).to have_content('You do not have an active subscription')
      end
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

          expect(page).to have_content('Subscription detail synchronization has started and will complete soon.')
        end
      end

      it 'fails to sync the subscription' do
        create_current_license_without_expiration(cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN)

        page.within(find('#content-body', match: :first)) do
          click_button('Sync subscription details')

          expect(page).to have_content('Subscription details did not synchronize due to a possible connectivity issue with GitLab servers. How do I check connectivity?')
        end
      end

      it_behaves_like 'an "Export license usage file" button'
      it_behaves_like 'license removal'
    end
  end

  context 'with license file' do
    let!(:license) { create_current_license(cloud_licensing_enabled: false, plan: License::ULTIMATE_PLAN) }

    before do
      visit(admin_subscription_path)
    end

    it_behaves_like 'an "Export license usage file" button'
    it_behaves_like 'license removal'

    context 'when activating another subscription' do
      before do
        page.within(find('[data-testid="subscription-details"]', match: :first)) do
          click_button('Add activation code')
        end
      end

      it 'shows the activation modal',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391275' do
        within_modal do
          expect(page).to have_content('Activate subscription')
        end
      end

      it 'displays an error when the activation fails',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/390580' do
        stub_request(:post, graphql_url).to_return(status: 422, body: '', headers: {})

        within_modal do
          fill_activation_form

          expect(page).to have_content('An error occurred while adding your subscription')
        end
      end

      it 'displays a connectivity error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/391244' do
        stub_request(:post, graphql_url)
          .to_return(status: 500, body: '', headers: {})

        within_modal do
          fill_activation_form

          expect(page).to have_content('Cannot activate instance due to a connectivity issue')
        end
      end
    end
  end

  context 'with no active subscription' do
    let_it_be(:license_to_be_created) { nil }

    before do
      License.current.destroy!

      visit(admin_subscription_path)
    end

    it_behaves_like 'no active license'

    it 'does not display the Export License Usage File button' do
      expect(page).not_to have_link('Export license usage file', href: admin_license_usage_export_path(format: :csv))
    end

    context 'when activating a subscription fails' do
      before do
        stub_request(:post, graphql_url)
          .to_return(status: 200, body: {
            "data": {
              "cloudActivationActivate": {
                "errors": ["invalid activation code"],
                "license": license_to_be_created
              },
              "success": "true"
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        page.within(find('#content-body', match: :first)) do
          fill_activation_form
        end
      end

      it 'shows the general error message' do
        expect(page).to have_content('An error occurred while adding your subscription')
      end
    end

    context 'when license is expired' do
      let_it_be(:license_to_be_created) { build(:license, data: build(:gitlab_license, { starts_at: Date.current - 1.year - 1.month, expires_at: Date.current - 1.month, cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN }).export) }

      before do
        stub_request(:post, graphql_url)
          .to_return(status: 200, body: {
            "data": {
              "cloudActivationActivate": {
                "licenseKey": license_to_be_created.data
              }
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        page.within(find('#content-body', match: :first)) do
          fill_activation_form
        end
      end

      it 'shows the license expired error message' do
        expect(page).to have_content('Your subscription is expired')
      end
    end

    context 'when activating a future-dated subscription' do
      let_it_be(:license_to_be_created) { build(:license, data: build(:gitlab_license, { starts_at: Date.current + 1.month, cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN }).export) }

      before do
        stub_request(:post, graphql_url)
          .to_return(status: 200, body: {
            "data": {
              "cloudActivationActivate": {
                "licenseKey": license_to_be_created.data
              }
            }
          }.to_json, headers: { 'Content-Type' => 'application/json' })

        page.within(find('#content-body', match: :first)) do
          fill_activation_form
        end
      end

      it 'shows a successful future-dated activation message' do
        expect(page).to have_content('Your future dated license was successfully added')
      end

      it_behaves_like 'no active license'
    end

    context 'when activating a new subscription' do
      let_it_be(:license_to_be_created) { build(:license, data: build(:gitlab_license, { starts_at: Date.current, cloud_licensing_enabled: true, plan: License::ULTIMATE_PLAN }).export) }

      before do
        stub_request(:post, graphql_url)
          .to_return(status: 200, body: {
            "data": {
              "cloudActivationActivate": {
                "licenseKey": license_to_be_created.data
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
          expect(page).to have_content('Online license')
        end
      end
    end

    context 'when uploading a license file' do
      it 'does not show a link to activate a license file' do
        page.within(find('#content-body', match: :first)) do
          expect(page).not_to have_link('Activate a license', href: general_admin_application_settings_path)
        end
      end
    end
  end

  include_examples 'manual quarterly co-term banner', path_to_visit: :admin_subscription_path

  private

  def fill_activation_form
    fill_in 'activationCode', with: '00112233aaaassssddddffff'
    check 'subscription-form-terms-check'
    click_button 'Activate'
  end
end
