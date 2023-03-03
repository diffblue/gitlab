# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateService, feature_category: :billing_and_payments do
  subject(:execute) { described_class.new(user, group: group, customer_params: customer_params, subscription_params: subscription_params).execute }

  let_it_be(:user) { create(:user, id: 111, first_name: 'First name', last_name: 'Last name', email: 'first.last@gitlab.com') }
  let_it_be(:group) { create(:group, id: 222, name: 'Group name') }
  let_it_be(:oauth_app) { create(:oauth_application) }

  let_it_be(:customer_params) do
    {
      country: 'NL',
      address_1: 'Address line 1',
      address_2: 'Address line 2',
      city: 'City',
      state: 'State',
      zip_code: 'Zip code',
      company: 'My organization'
    }
  end

  let_it_be(:subscription_params) do
    {
      plan_id: 'Plan ID',
      payment_method_id: 'Payment method ID',
      quantity: 123,
      source: 'some_source'
    }
  end

  let_it_be(:customer_email) { 'first.last@gitlab.com' }
  let_it_be(:client) { Gitlab::SubscriptionPortal::Client }
  let_it_be(:create_service_params) { Gitlab::Json.parse(fixture_file('create_service_params.json', dir: 'ee'))["subscription_params"].deep_symbolize_keys }

  describe '#execute' do
    before do
      allow(client).to receive(:customers_oauth_app_uid).and_return( data: { 'oauth_app_id' => oauth_app.uid })
      allow(Doorkeeper::OAuth::Helpers::UniqueToken).to receive(:generate).and_return('foo_token')
    end

    context 'when failing to create a customer' do
      before do
        allow(client).to receive(:create_customer).and_return(success: false, data: { errors: 'failed to create customer' })
      end

      it 'returns the response hash' do
        expect(execute).to eq(success: false, data: { errors: 'failed to create customer' })
      end

      it 'does not save oauth token' do
        expect { execute }.not_to change(OauthAccessToken, :count)
      end
    end

    context 'when successfully creating a customer' do
      before do
        allow(client).to receive(:create_customer).and_return(success: true, data: { success: true, 'customer' => { 'authentication_token' => 'token', 'email' => customer_email } })

        allow(client)
          .to receive(:create_subscription)
          .with(anything, customer_email, 'token')
          .and_return(success: true, data: { success: true, subscription_id: 'xxx' })
      end

      it 'creates a subscription with the returned authentication token' do
        execute

        expect(client).to have_received(:create_subscription).with(anything, customer_email, 'token')
      end

      it 'saves oauth token' do
        expect { execute }.to change(OauthAccessToken, :count).by(1)
      end

      it 'creates oauth token with correct application id and expiration' do
        now = Time.current.beginning_of_hour

        travel_to(now) do
          execute

          created_oauth_token = OauthAccessToken.by_token('foo_token')

          expect(created_oauth_token.application_id).to eq(oauth_app.id)
          expect(created_oauth_token.expires_at).to eq now + 2.hours
        end
      end

      context 'when failing to create a subscription' do
        before do
          allow(client).to receive(:create_subscription).and_return(success: false, data: { errors: 'failed to create subscription' })
        end

        it 'returns the response hash' do
          expect(execute).to eq(success: false, data: { errors: 'failed to create subscription' })
        end

        it_behaves_like 'does not record an onboarding progress action'
      end

      context 'when successfully creating a subscription' do
        before do
          allow(client).to receive(:create_subscription).and_return(success: true, data: { success: true, subscription_id: 'xxx' })
        end

        it 'returns the response hash' do
          expect(execute).to eq(success: true, data: { success: true, subscription_id: 'xxx' })
        end
      end
    end

    context 'passing the correct parameters to the client' do
      before do
        allow(client).to receive(:create_customer).and_return(success: true, data: { success: true, customer: { authentication_token: 'token', email: customer_email } })
        allow(client).to receive(:create_subscription).and_return(success: true, data: { success: true, subscription_id: 'xxx' })
      end

      it 'passes the correct parameters for creating a customer' do
        expect(client).to receive(:create_customer).with(create_service_params[:customer])

        execute
      end

      it 'passes the correct parameters for creating a subscription' do
        expect(client).to receive(:create_subscription).with(create_service_params[:subscription], customer_email, 'token')

        execute
      end

      context 'with subscription purchase using promo code' do
        let_it_be(:subscription_params) do
          {
            plan_id: "Plan ID",
            payment_method_id: "Payment method ID",
            quantity: 123,
            promo_code: "Sample promo code",
            source: "some_source"
          }
        end

        it 'passes the correct parameters for creating a subscription' do
          create_params = Gitlab::Json.parse(fixture_file('create_service_params.json', dir: 'ee'))["subscription_params_with_promo_code"].deep_symbolize_keys

          expect(client).to receive(:create_subscription).with(create_params[:subscription], customer_email, 'token')

          execute
        end
      end

      context 'with add-on purchase' do
        let_it_be(:subscription_params) do
          {
            is_addon: true,
            plan_id: 'Add-on Plan ID',
            payment_method_id: 'Payment method ID',
            quantity: 111,
            source: 'some_source'
          }
        end

        context 'without active subscription' do
          it 'passes the correct parameters for creating a subscription' do
            create_service_addon_params = Gitlab::Json.parse(fixture_file('create_service_params.json', dir: 'ee'))["addon_without_active_sub"].deep_symbolize_keys

            expect(client).to receive(:create_subscription).with(create_service_addon_params[:subscription], customer_email, 'token')

            execute
          end
        end

        context 'with active subscription' do
          before do
            subscription_params[:active_subscription] = 'A-000000'
          end

          it 'passes the correct parameters for creating a subscription' do
            create_service_addon_params = Gitlab::Json.parse(fixture_file('create_service_params.json', dir: 'ee'))["addon_with_active_sub"].deep_symbolize_keys

            expect(client).to receive(:create_subscription).with(create_service_addon_params[:subscription], customer_email, 'token')

            execute
          end
        end
      end

      it_behaves_like 'records an onboarding progress action', :subscription_created do
        let(:namespace) { group }
      end
    end
  end
end
