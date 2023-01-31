# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExpiringSubscriptionMessage, :saas do
  include ActionView::Helpers::SanitizeHelper

  describe 'message' do
    using RSpec::Parameterized::TableSyntax

    subject(:message) { strip_tags(raw_message) }

    let(:subject) { strip_tags(raw_subject) }
    let(:subscribable) { double(:license) }
    let(:namespace) { nil }
    let(:force_notification) { false }
    let(:raw_message) do
      described_class.new(
        subscribable: subscribable,
        signed_in: true,
        is_admin: true,
        namespace: namespace,
        force_notification: force_notification
      ).message
    end

    let(:raw_subject) do
      described_class.new(
        subscribable: subscribable,
        signed_in: true,
        is_admin: true,
        namespace: namespace,
        force_notification: force_notification
      ).subject
    end

    let(:today) { Time.utc(2020, 3, 7, 10) }
    let(:expired_date) { Time.utc(2020, 3, 9, 10).to_date }
    let(:block_changes_date) { Time.utc(2020, 3, 23, 10).to_date }

    where(:plan_name) do
      [
        [::Plan::GOLD],
        [::Plan::ULTIMATE]
      ]
    end

    with_them do
      around do |example|
        travel_to(today) do
          example.run
        end
      end

      context 'subscribable installed' do
        let(:auto_renew) { false }

        before do
          allow(subscribable).to receive(:plan).and_return(plan_name)
          allow(subscribable).to receive(:expires_at).and_return(expired_date)
          allow(subscribable).to receive(:auto_renew).and_return(auto_renew)
        end

        context 'subscribable should not notify admins' do
          it 'returns nil' do
            allow(subscribable).to receive(:notify_admins?).and_return(false)
            allow(subscribable).to receive(:notify_users?).and_return(false)

            expect(message).to be nil
          end
        end

        context 'subscribable should notify admins' do
          before do
            allow(subscribable).to receive(:notify_admins?).and_return(true)
          end

          context 'admin signed in' do
            let(:signed_in) { true }
            let(:is_admin) { true }

            context 'subscribable expired' do
              let(:expired_date) { Time.utc(2020, 3, 1, 10).to_date }

              before do
                allow(subscribable).to receive(:expired?).and_return(true)
                allow(subscribable).to receive(:expires_at).and_return(expired_date)
              end

              context 'when it blocks changes' do
                before do
                  allow(subscribable).to receive(:will_block_changes?).and_return(true)
                end

                context 'when it is currently blocking changes' do
                  let(:plan_name) { ::Plan::FREE }

                  before do
                    allow(subscribable).to receive(:block_changes?).and_return(true)
                    allow(subscribable).to receive(:block_changes_at).and_return(expired_date)
                  end

                  context "when the subscription hasn't been properly downgraded yet" do
                    let(:plan_name) { ::Plan::PREMIUM }

                    it "shows the expiring message" do
                      expect(message).to include('No worries, you can still use all the Premium features for now. You have 0 days to renew your subscription.')
                    end
                  end

                  it 'has a nice subject' do
                    expect(subject).to include('Your subscription expired!')
                  end

                  context 'no namespace' do
                    it 'has an expiration blocking message' do
                      expect(message).to include('Please delete your current license if you want to downgrade to the free plan')
                    end
                  end

                  context 'with namespace' do
                    let(:has_future_renewal) { false }

                    let_it_be(:namespace) { create(:group_with_plan, name: 'No Limit Records') }

                    before do
                      allow_next_instance_of(GitlabSubscriptions::CheckFutureRenewalService, namespace: namespace) do |service|
                        allow(service).to receive(:execute).and_return(has_future_renewal)
                      end
                    end

                    it 'has an expiration blocking message' do
                      expect(message).to include("Your subscription for No Limit Records has expired and you are now on the GitLab Free tier. Don't worry, your data is safe. Get in touch with our support team (support@gitlab.com). They'll gladly help with your subscription renewal.")
                    end

                    context 'is auto_renew' do
                      let(:auto_renew) { true }

                      it 'has a nice subject' do
                        expect(subject).to include('Something went wrong with your automatic subscription renewal')
                      end

                      it 'has an expiration blocking message' do
                        expect(message).to include("We tried to automatically renew your subscription for No Limit Records on 2020-03-01 but something went wrong so your subscription was downgraded to the free plan. Don't worry, your data is safe. We suggest you check your payment method and get in touch with our support team (support.gitlab.com). They'll gladly help with your subscription renewal.")
                      end
                    end

                    context 'when there is a future renewal' do
                      let(:has_future_renewal) { true }

                      it { is_expected.to be_nil }
                    end

                    context 'without gitlab_subscription' do
                      let(:namespace) { build(:group, name: 'No Subscription Records') }

                      it 'does not check for a future renewal' do
                        expect(GitlabSubscriptions::CheckFutureRenewalService).not_to receive(:new)

                        message
                      end
                    end
                  end
                end

                context 'when it is not currently blocking changes' do
                  let(:plan_name) { ::Plan::ULTIMATE }

                  before do
                    allow(subscribable).to receive(:block_changes?).and_return(false)
                    allow(subscribable).to receive(:block_changes_at).and_return((today + 4.days).to_date)
                  end

                  it 'has a nice subject' do
                    allow(subscribable).to receive(:will_block_changes?).and_return(false)

                    expect(subject).to include('Your subscription expired!')
                  end

                  it 'has an expiration blocking message' do
                    allow(subscribable).to receive(:block_changes_at).and_return(Time.utc(2020, 3, 9, 10).to_date)
                    allow(subscribable).to receive(:is_a?).with(::License).and_return(true)

                    expect(message).to include('No worries, you can still use all the Ultimate features for now. You have 2 days to renew your subscription.')
                  end
                end
              end
            end

            context 'subscribable is expiring soon' do
              before do
                allow(subscribable).to receive(:expired?).and_return(false)
                allow(subscribable).to receive(:will_block_changes?).and_return(true)
                allow(subscribable).to receive(:block_changes_at).and_return(block_changes_date)
              end

              it 'has a nice subject' do
                expect(subject).to include("Your #{plan_name.capitalize} subscription will expire on #{expired_date.strftime("%Y-%m-%d")}")
              end

              context 'without namespace' do
                it 'has an expiration blocking message' do
                  expect(message).to include("If you don\'t renew by #{block_changes_date.strftime("%Y-%m-%d")} your instance will become read-only, and you won't be able to create issues or merge requests. You will also lose access to your paid features and support entitlement. How do I renew my subscription?")
                end
              end

              context 'when a future dated license is applied' do
                before do
                  create(:license, created_at: Time.current, data: build(:gitlab_license, starts_at: expired_date, expires_at: Date.current + 13.months).export)
                end

                it 'returns nil' do
                  expect(message).to be nil
                end
              end

              context 'when self-managed subscription is already renewed' do
                before do
                  allow(subscribable).to receive(:is_a?).with(::License).and_return(true)
                  allow(::Gitlab::CurrentSettings.current_application_settings).to receive(
                    :future_subscriptions
                  ).and_return([{ 'license' => 'test' }])
                end

                it 'does not return a message' do
                  expect(message).to be_nil
                end
              end

              context 'with namespace' do
                using RSpec::Parameterized::TableSyntax

                let_it_be(:group_with_plan) { create(:group_with_plan, name: 'No Limit Records') }

                let(:has_future_renewal) { false }
                let(:namespace) { group_with_plan }

                before do
                  allow_next_instance_of(GitlabSubscriptions::CheckFutureRenewalService, namespace: namespace) do |service|
                    allow(service).to receive(:execute).and_return(has_future_renewal)
                  end

                  allow_next_instance_of(Group) do |group|
                    allow(group).to receive(:gitlab_subscription).and_return(gitlab_subscription)
                  end
                end

                where plan: %w(gold ultimate)

                with_them do
                  it 'has plan specific messaging' do
                    allow(subscribable).to receive(:plan).and_return(plan)

                    expect(message).to include("Your #{plan.capitalize} subscription for No Limit Records will expire on 2020-03-09. If you do not renew by 2020-03-23, you can't use merge approvals, epics, security risk mitigation, or any other paid features.")
                  end
                end

                where plan: %w(silver premium)

                with_them do
                  it 'has plan specific messaging' do
                    allow(subscribable).to receive(:plan).and_return('premium')

                    expect(message).to include("Your Premium subscription for No Limit Records will expire on 2020-03-09. If you do not renew by 2020-03-23, you can't use merge approvals, epics, or any other paid features.")
                  end
                end

                it 'has bronze plan specific messaging' do
                  allow(subscribable).to receive(:plan).and_return('bronze')

                  expect(message).to include("Your Bronze subscription for No Limit Records will expire on 2020-03-09. If you do not renew by 2020-03-23, you can't use merge approvals, code quality, or any other paid features.")
                end

                context 'is auto_renew nil' do
                  let(:auto_renew) { nil }

                  it 'returns nil' do
                    expect(message).to be nil
                  end
                end

                context 'is auto_renew' do
                  let(:auto_renew) { true }

                  it 'returns nil' do
                    expect(message).to be nil
                  end
                end

                context 'when there is a future renewal' do
                  let(:has_future_renewal) { true }

                  it { is_expected.to be_nil }
                end

                context 'without gitlab_subscription' do
                  let(:namespace) { build(:group, name: 'No Subscription Records') }

                  it 'does not check for a future renewal' do
                    expect(GitlabSubscriptions::CheckFutureRenewalService).not_to receive(:new)

                    message
                  end
                end

                context 'with a sub-group' do
                  let(:namespace) { build(:group, parent: group_with_plan) }

                  it 'checks for a future renewal' do
                    expect(GitlabSubscriptions::CheckFutureRenewalService).to receive(:new)

                    message
                  end

                  context 'when parent namespace has a future renewal' do
                    let(:has_future_renewal) { true }

                    it { is_expected.to be_nil }
                  end
                end
              end
            end
          end
        end
      end

      context 'no subscribable installed' do
        let(:subscribable) { nil }

        it { is_expected.to be_blank }
      end
    end
  end
end
