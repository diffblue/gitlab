# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Billing plan pages', :feature, :saas, :js, feature_category: :billing_and_payments do
  include SubscriptionPortalHelpers
  include BillingPlansHelpers

  let(:user) { create(:user, first_name: 'James', last_name: 'Bond', organization: 'ACME') }
  let(:auditor) { create(:auditor, first_name: 'James', last_name: 'Bond', organization: 'ACME') }
  let(:namespace) { user.namespace }
  let(:free_plan) { create(:free_plan) }
  let(:bronze_plan) { create(:bronze_plan) }
  let(:premium_plan) { create(:premium_plan) }
  let(:ultimate_plan) { create(:ultimate_plan) }

  let(:plans_data) { billing_plans_data }

  before do
    stub_signing_key
    stub_application_setting(check_namespace_plan: true)

    stub_feature_flags(show_billing_eoa_banner: true)
    stub_feature_flags(hide_deprecated_billing_plans: false)

    stub_billing_plans(nil)
    stub_billing_plans(namespace.id, plan.name, plans_data.to_json)
    stub_eoa_eligibility_request(namespace.id)
    stub_subscription_management_data(namespace.id)

    sign_in(user)
  end

  def external_upgrade_url(namespace, plan)
    subscription_portal_url = ::Gitlab::Routing.url_helpers.subscription_portal_url

    if Plan::PAID_HOSTED_PLANS.include?(plan.name)
      "#{subscription_portal_url}/gitlab/namespaces/#{namespace.id}/upgrade/#{plan.name}-external-id"
    end
  end

  shared_examples 'does not display EoA banner' do
    it 'does not display the banner', :js do
      travel_to(Date.parse(EE::Users::CalloutsHelper::EOA_BRONZE_PLAN_END_DATE) - 1.day) do
        visit page_path

        expect(page).not_to have_content("End of availability for the Bronze Plan")
      end
    end
  end

  shared_examples 'does not display the billing plans' do
    it 'does not display the plans' do
      expect(page).not_to have_selector("[data-testid='billing-plans']")
    end
  end

  shared_examples 'upgradable plan' do
    before do
      visit page_path
    end

    it 'displays the upgrade link' do
      page.within('.content') do
        expect(page).to have_link('Upgrade', href: external_upgrade_url(namespace, plan))
      end
    end
  end

  shared_examples 'can not contact sales' do
    before do
      visit page_path
    end

    it 'does not render in-app hand raise lead' do
      should_have_hand_raise_lead_button
    end
  end

  shared_examples 'non-upgradable plan' do
    before do
      visit page_path
    end

    it 'does not display the upgrade link' do
      page.within('.content') do
        expect(page).not_to have_link('Upgrade', href: external_upgrade_url(namespace, plan))
      end
    end
  end

  shared_examples 'downgradable plan' do
    before do
      visit page_path
    end

    it 'displays the downgrade link' do
      page.within('.content') do
        expect(page).to have_content('downgrade your plan')
        expect(page).to have_link('Customer Support', href: EE::CUSTOMER_SUPPORT_URL)
      end
    end
  end

  shared_examples 'plan with header' do
    before do
      visit page_path
    end

    it 'displays header' do
      page.within('.billing-plan-header') do
        expect(page).to have_content("#{user.username} you are currently using the #{plan.name.titleize} Plan.")

        expect(page).to have_css('.billing-plan-logo img')
      end
    end
  end

  shared_examples 'plan with subscription table' do
    before do
      visit page_path
    end

    it 'displays subscription table' do
      expect(page).to have_selector('.js-subscription-table')
    end
  end

  shared_examples 'used seats rendering for non paid subscriptions' do
    before do
      visit page_path
    end

    it 'displays the number of seats' do
      page.within('.js-subscription-table') do
        expect(page).to have_selector('p.property-value.gl-mt-2.gl-mb-0.number', text: '1')
      end
    end
  end

  context 'users profile billing page' do
    let(:page_path) { profile_billings_path }

    context 'on free' do
      let(:plan) { free_plan }

      before do
        visit page_path
      end

      it 'displays the correct call to action', :js do
        page.within('.billing-plan-header') do
          expect(page).to have_content('Looking to purchase or manage a subscription for your group? Navigate to your group and go to Settings > Billing')
          expect(page).to have_link('group', href: dashboard_groups_path)
        end
      end

      it_behaves_like 'does not display the billing plans'
      it_behaves_like 'plan with subscription table'
    end

    context 'on bronze plan' do
      let(:plan) { bronze_plan }

      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      it 'shows the EoA bronze banner that can be dismissed permanently', :js do
        travel_to(Date.parse(EE::Users::CalloutsHelper::EOA_BRONZE_PLAN_END_DATE) - 1.day) do
          visit page_path

          page.within(".js-eoa-bronze-plan-banner") do
            expect(page).to have_content("End of availability for the Bronze Plan")

            click_button "Dismiss"
          end

          visit page_path

          expect(page).not_to have_content("End of availability for the Bronze Plan")
        end
      end

      it_behaves_like 'plan with header'
      it_behaves_like 'downgradable plan'
      it_behaves_like 'upgradable plan'
      it_behaves_like 'can not contact sales'
      it_behaves_like 'plan with subscription table'

      context 'when hide_deprecated_billing_plans is active' do
        let(:premium_plan_data) { plans_data.find { |plan_data| plan_data[:id] == 'premium-external-id' } }

        before do
          stub_feature_flags(hide_deprecated_billing_plans: true)
          stub_eoa_eligibility_request(namespace.id, true, premium_plan_data[:id])
        end

        it 'displays the free upgrade' do
          visit page_path

          within '.card-badge' do
            expect(page).to have_text('Free upgrade!')
          end
        end

        context 'with an active deprecated plan' do
          let(:legacy_plan) { plans_data.find { |plan_data| plan_data[:id] == 'bronze-external-id' } }
          let(:expected_card_header) { "#{legacy_plan[:name]} (Legacy)" }

          before do
            stub_feature_flags(hide_deprecated_billing_plans: true)

            visit page_path
          end

          it 'renders the plan card marked as Legacy' do
            page.within("[data-testid='billing-plans']") do
              panels = page.all('.card')
              expect(panels.length).to eq(plans_data.length)

              panel_with_legacy_plan = page.find("[data-testid='plan-card-#{legacy_plan[:code]}']")

              expect(panel_with_legacy_plan.find('.card-header')).to have_content(expected_card_header)
              expect(panel_with_legacy_plan.find('.card-body')).to have_link('frequently asked questions')
            end
          end
        end

        context 'with more than 25 users' do
          let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 30) }

          before do
            stub_eoa_eligibility_request(namespace.id, false, premium_plan_data[:id])
          end

          it 'displays the sales assisted offer' do
            visit page_path

            within '.card-badge' do
              expect(page).to have_text('Upgrade offers available!')
            end
          end
        end
      end
    end

    context 'on premium plan' do
      let(:plan) { premium_plan }

      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      it_behaves_like 'plan with header'
      it_behaves_like 'downgradable plan'
      it_behaves_like 'upgradable plan'
      it_behaves_like 'can not contact sales'
      it_behaves_like 'plan with subscription table'
      it_behaves_like 'does not display EoA banner'
    end

    context 'on ultimate plan' do
      let(:plan) { ultimate_plan }

      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      it_behaves_like 'plan with header'
      it_behaves_like 'downgradable plan'
      it_behaves_like 'non-upgradable plan'
      it_behaves_like 'plan with subscription table'
      it_behaves_like 'does not display EoA banner'
    end

    context 'when CustomersDot is unavailable' do
      let(:plan) { ultimate_plan }
      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan) }

      before do
        stub_billing_plans(namespace.id, plan.name, raise_error: 'Connection refused')
      end

      it 'renders an error page' do
        visit page_path

        expect(page).to have_content("Subscription service outage")
      end
    end
  end

  context 'users profile billing page with a trial' do
    let(:page_path) { profile_billings_path }

    context 'on free' do
      let(:plan) { free_plan }

      let!(:subscription) do
        create(:gitlab_subscription,
               namespace: namespace, hosted_plan: plan,
               trial: true, trial_ends_on: Date.current.tomorrow, seats: 15)
      end

      before do
        visit page_path
      end

      it_behaves_like 'does not display the billing plans'
    end

    context 'on bronze plan' do
      let(:plan) { bronze_plan }

      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      it_behaves_like 'plan with header'
      it_behaves_like 'downgradable plan'
      it_behaves_like 'upgradable plan'
      it_behaves_like 'can not contact sales'
    end

    context 'on ultimate plan' do
      let(:plan) { ultimate_plan }

      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      it_behaves_like 'plan with header'
      it_behaves_like 'downgradable plan'
      it_behaves_like 'non-upgradable plan'
    end
  end

  context 'group billing page' do
    let(:namespace) { create(:group) }
    let!(:group_member) { create(:group_member, :owner, group: namespace, user: user) }

    shared_context 'hand raise lead form setup' do
      let(:form_data) do
        {
          first_name: user.first_name,
          last_name: user.last_name,
          phone_number: '+1 23 456-78-90',
          company_size: '1 - 99',
          company_name: user.organization,
          country: { id: 'US', name: 'United States of America' },
          state: { id: 'CA', name: 'California' }
        }
      end

      let(:hand_raise_lead_params) do
        {
          "first_name" => form_data[:first_name],
          "last_name" => form_data[:last_name],
          "company_name" => form_data[:company_name],
          "company_size" => form_data[:company_size].delete(' '),
          "phone_number" => form_data[:phone_number],
          "country" => form_data.dig(:country, :id),
          "state" => form_data.dig(:state, :id),
          "namespace_id" => namespace.id,
          "comment" => '',
          "glm_content" => 'billing-group',
          "work_email" => user.email,
          "uid" => user.id,
          "setup_for_company" => user.setup_for_company,
          "provider" => "gitlab",
          "glm_source" => 'gitlab.com'
        }
      end

      let(:lead_params) { ActionController::Parameters.new(hand_raise_lead_params).permit! }

      before do
        expect_next_instance_of(GitlabSubscriptions::CreateHandRaiseLeadService) do |service|
          expect(service).to receive(:execute).with(lead_params).and_return(double('lead', success?: true))
        end
      end
    end

    context 'when a group is the top-level group' do
      let(:page_path) { group_billings_path(namespace) }

      context 'on ultimate' do
        let(:plan) { ultimate_plan }

        let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

        before do
          visit page_path
        end

        it 'displays plan header' do
          page.within('.billing-plan-header') do
            expect(page).to have_content("#{namespace.name} is currently using the Ultimate Plan")

            expect(page).to have_css('.billing-plan-logo .identicon')
          end
        end

        it_behaves_like 'does not display the billing plans'
        it_behaves_like 'plan with subscription table'
      end

      context 'on bronze' do
        let(:plan) { bronze_plan }

        let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

        before do
          visit page_path
        end

        it 'displays plan header' do
          page.within('.billing-plan-header') do
            expect(page).to have_content("#{namespace.name} is currently using the Bronze Plan")

            expect(page).to have_css('.billing-plan-logo .identicon')
          end
        end

        it 'does display the billing plans table' do
          expect(page).to have_selector("[data-testid='billing-plans']")
        end

        context 'when submitting hand raise lead' do
          include_context 'hand raise lead form setup'

          it 'displays the in-app hand raise lead' do
            click_premium_contact_sales_button_and_submit_form
          end
        end

        it_behaves_like 'plan with subscription table'
      end

      context 'on free' do
        let(:plan) { free_plan }

        include_context 'hand raise lead form setup'

        it 'submits hand raise lead form' do
          visit page_path

          click_button 'Talk to an expert today'

          fill_hand_raise_lead_form_and_submit
        end
      end

      context 'on trial' do
        let(:plan) { free_plan }

        let!(:subscription) do
          create(:gitlab_subscription, :active_trial,
            namespace: namespace,
            hosted_plan: premium_plan,
            seats: 15
          )
        end

        before do
          visit page_path
        end

        it 'displays the billing plans table' do
          expect(page).to have_selector("[data-testid='billing-plans']")
        end

        it_behaves_like 'non-upgradable plan'
        it_behaves_like 'used seats rendering for non paid subscriptions'
        it_behaves_like 'plan with subscription table'
      end

      context 'with auditor user' do
        let(:plan) { ultimate_plan }
        let!(:group_member) { create(:group_member, :guest, group: namespace, user: auditor) }
        let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

        before do
          stub_licensed_features(auditor_user: true)

          sign_in(auditor)

          visit page_path
        end

        it_behaves_like 'does not display the billing plans'
        it_behaves_like 'plan with subscription table'
      end
    end

    context 'when a group is the subgroup' do
      let(:namespace) { create(:group_with_plan) }
      let(:plan) { namespace.actual_plan }
      let(:subgroup) { create(:group, parent: namespace) }

      it 'shows the subgroup page context for billing', :aggregate_failures do
        visit group_billings_path(subgroup)

        expect(page).to have_text('is currently using the')
        expect(page).to have_text('This group uses the plan associated with its parent group')
        expect(page).to have_link('Manage plan')
        expect(page).not_to have_selector("[data-testid='billing-plans']")
      end
    end

    context 'seat refresh button' do
      let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

      let(:page_path) { group_billings_path(namespace) }
      let(:plan) { ultimate_plan }

      it 'updates seat counts on click' do
        visit page_path

        expect(seats_in_use).to eq '0'

        click_button 'Refresh Seats'
        wait_for_requests

        expect(seats_in_use).to eq '1'
      end
    end

    def seats_in_use
      all('[data-testid="content-cell"]').each do |cell|
        label = cell.first('[data-testid="property-label"]')
        break cell.find('[data-testid="property-value"]').text if label&.text == 'Seats currently in use'
      end
    end

    def fill_hand_raise_lead_form_and_submit
      page.within('[data-testid="hand-raise-lead-modal"]') do
        aggregate_failures do
          expect(page).to have_content('Contact our Sales team')
          expect(page).to have_field('First Name', with: form_data[:first_name])
          expect(page).to have_field('Last Name', with: form_data[:last_name])
          expect(page).to have_field('Company Name', with: form_data[:company_name])
        end

        select form_data[:company_size], from: 'company-size'
        fill_in 'phone-number', with: form_data[:phone_number]
        select form_data.dig(:country, :name), from: 'country'
        select form_data.dig(:state, :name), from: 'state'

        click_button 'Submit information'
      end
    end
  end

  context 'with unexpected JSON' do
    let(:plan) { premium_plan }

    let!(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }

    let(:plans_data) do
      [
        {
          name: "Superhero",
          price_per_month: 999.0,
          free: true,
          code: "not-found",
          price_per_year: 111.0,
          purchase_link: {
            action: "upgrade",
            href: "http://customers.test.host/subscriptions/new?plan_id=super_hero_id"
          },
          features: []
        }
      ]
    end

    before do
      visit profile_billings_path
    end

    it 'renders no header for missing plan' do
      expect(page).not_to have_css('.billing-plan-header')
    end

    it 'displays all plans' do
      page.within("[data-testid='billing-plans']") do
        panels = page.all('.card')
        expect(panels.length).to eq(plans_data.length)
        plans_data.each_with_index do |data, index|
          expect(panels[index].find('.card-header')).to have_content(data[:name])
        end
      end
    end
  end
end
