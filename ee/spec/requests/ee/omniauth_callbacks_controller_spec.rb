# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, feature_category: :system_access do
  include LoginHelpers
  include SessionHelpers

  context 'with strategies', :aggregate_failures do
    let(:provider) { :github }
    let(:check_namespace_plan) { true }

    before do
      stub_omniauth_setting(block_auto_created_users: false)
      mock_auth_hash(provider.to_s, 'my-uid', user.email)
    end

    around do |example|
      with_omniauth_full_host { example.run }
    end

    context 'when user is not registered yet', :clean_gitlab_redis_sessions do
      let(:user) { build_stubbed(:user, email: 'new@example.com') }
      let(:path) { '/user/return/to/path' }

      before do
        stub_session(user_return_to: path)
      end

      it 'wipes the previously stored location for user' do
        expect_next_instance_of(described_class) do |controller|
          expect(controller).to receive(:store_location_for).with(:user, users_sign_up_welcome_path)
        end

        post public_send("user_#{provider}_omniauth_callback_path")

        expect(request.env['warden']).to be_authenticated
      end

      context 'when user is in subscription onboarding' do
        let(:path) { new_subscriptions_path(plan_id: 'bronze_id') }

        it 'preserves the previously stored location for user' do
          expect_next_instance_of(described_class) do |controller|
            expect(controller).not_to receive(:store_location_for).with(:user)
          end

          post public_send("user_#{provider}_omniauth_callback_path")

          expect(request.env['warden']).to be_authenticated
        end
      end
    end
  end
end
