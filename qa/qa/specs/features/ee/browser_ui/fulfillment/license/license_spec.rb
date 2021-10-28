# frozen_string_literal: true

module QA
  include QA::Support::Helpers::Plan

  RSpec.describe 'Fulfillment', :requires_admin, :skip_live_env, except: { job: 'review-qa-*' } do
    let(:user) { 'GitLab QA' }
    let(:user_email) { 'gitlab-qa@gitlab.com' }
    let(:company) { 'GitLab' }
    let(:user_count) { 10000 }
    let(:plan) { ULTIMATE_SELF_MANAGED }

    context 'Active license details' do
      before do
        Flow::Login.sign_in_as_admin
        Gitlab::Page::Admin::Subscription.perform(&:visit)
      end

      it 'shows up in subscription page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2341' do
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          aggregate_failures do
            expect { subscription.name }.to eventually_eq(user).within(max_duration: 30)
            expect(subscription.email).to eq(user_email)
            expect(subscription.company).to eq(company)
            expect(subscription.plan).to eq(plan[:name].capitalize)
            expect(subscription.users_in_subscription).to eq(user_count.to_s)
            expect(subscription_record_exists(plan, user_count, LICENSE_TYPE[:license_file])).to be(true)
          end
        end
      end

      private

      # Checks if a subscription record exists in subscription history table
      #
      # @param plan [Hash] Name of the plan
      # @option plan [Hash] Support::Helpers::FREE
      # @option plan [Hash] Support::Helpers::PREMIUM
      # @option plan [Hash] Support::Helpers::PREMIUM_SELF_MANAGED
      # @option plan [Hash] Support::Helpers::ULTIMATE
      # @option plan [Hash] Support::Helpers::ULTIMATE_SELF_MANAGED
      # @option plan [Hash] Support::Helpers::CI_MINUTES
      # @option plan [Hash] Support::Helpers::STORAGE
      # @param users_in_license [Integer] Number of users in license
      # @param license_type [Hash] Type of the license
      # @option license_type [String] 'license file'
      # @option license_type [String] 'cloud license'
      # @return [Boolean] True if record exsists, false if not
      def subscription_record_exists(plan, users_in_license, license_type)
        Gitlab::Page::Admin::Subscription.perform do |subscription|
          # find any records that have a matching plan and seats and type
          subscription.subscription_history_element.hashes.any? do |record|
            record['Plan'] == plan[:name].capitalize && record['Seats'] == users_in_license.to_s && \
              record['Type'].strip.downcase == license_type
          end
        end
      end
    end
  end
end
