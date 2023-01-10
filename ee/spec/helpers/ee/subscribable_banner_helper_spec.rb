# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::SubscribableBannerHelper, :saas do
  describe '#renew_subscription_path' do
    it 'does not raise error if available project is not persisted' do
      assign(:project, Project.new)

      expect { helper.renew_subscription_path }.not_to raise_error
    end

    it 'does not raise error if entity is not available' do
      assign(:project, nil)
      assign(:group, nil)

      expect { helper.renew_subscription_path }.not_to raise_error
    end
  end

  describe '#gitlab_subscription_or_license' do
    subject { helper.gitlab_subscription_or_license }

    shared_examples 'when a subscription exists' do
      let(:gitlab_subscription) { build_stubbed(:gitlab_subscription) }
      let(:root_ancestor) { entity.root_ancestor }

      it 'returns a decorator' do
        allow(root_ancestor).to receive(:gitlab_subscription).and_return(gitlab_subscription)

        expect(subject).to be_a(SubscriptionPresenter)
      end
    end

    let(:license) { double(:license) }

    context 'when instance variable true' do
      before do
        assign(:display_subscription_banner, true)
      end

      context 'when should_check_namespace_plan is true' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
        end

        context 'when a project exists' do
          let(:entity) { create(:project) }

          before do
            assign(:project, entity)
          end

          it_behaves_like 'when a subscription exists'
        end

        context 'when a group exists' do
          let(:entity) { create(:group) }

          before do
            assign(:group, entity)
          end

          it_behaves_like 'when a subscription exists'
        end
      end

      context 'when should_check_namespace_plan is false' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
        end

        it 'returns the current license' do
          expect(License).to receive(:current).and_return(license)
          expect(subject).to eq(license)
        end
      end
    end

    context 'when instance variable false' do
      before do
        assign(:display_subscription_banner, false)
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      end

      it 'returns the current license' do
        expect(License).to receive(:current).and_return(license)
        expect(subject).to eq(license)
      end
    end

    context 'with a future dated license' do
      let(:gl_license) { build(:gitlab_license, starts_at: Date.current + 1.month) }

      before do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      end

      it 'returns the current license' do
        allow(License).to receive(:current).and_return(license)
        expect(subject).to eq(license)
      end
    end
  end

  describe '#gitlab_subscription_message_or_license_message' do
    subject { helper.gitlab_subscription_message_or_license_message }

    let(:message) { double(:message) }

    context 'when instance variable true' do
      before do
        assign(:display_subscription_banner, true)
      end

      context 'when should_check_namespace_plan is true' do
        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
        end

        let(:gitlab_subscription) { entity.root_ancestor.gitlab_subscription }
        let(:decorated_mock) { double(:decorated_mock) }
        let(:message_mock) { double(:message_mock) }
        let(:user) { double(:user_mock) }

        shared_examples 'subscription message' do
          it 'calls Gitlab::ExpiringSubscriptionMessage and SubscriptionPresenter if is Gitlab.com?' do
            allow(helper).to receive(:signed_in?).and_return(true)
            allow(helper).to receive(:current_user).and_return(user)
            allow(helper).to receive(:can?).with(user, :owner_access, root_namespace).and_return(true)

            expect(SubscriptionPresenter).to receive(:new).with(gitlab_subscription).and_return(decorated_mock)
            expect(::Gitlab::ExpiringSubscriptionMessage).to receive(:new).with(
              subscribable: decorated_mock,
              signed_in: true,
              is_admin: true,
              namespace: namespace
            ).and_return(message_mock)
            expect(message_mock).to receive(:message).and_return('hey yay yay yay')

            expect(subject).to eq('hey yay yay yay')
          end
        end

        let(:root_namespace) { create(:group_with_plan) }
        let(:namespace) { create(:group, :nested, parent: root_namespace) }

        context 'when a project is present' do
          let(:entity) { create(:project, namespace: namespace) }

          before do
            assign(:project, entity)
          end

          it_behaves_like 'subscription message'
        end

        context 'when a group is present' do
          let(:entity) { namespace }

          before do
            assign(:project, nil)
            assign(:group, entity)
          end

          it_behaves_like 'subscription message'
        end
      end

      context 'when should_check_namespace_plan is false' do
        let(:license) { double(:license) }
        let(:message_mock) { double(:message_mock) }
        let(:user) { double(:user) }

        before do
          allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
          allow(License).to receive(:current).and_return(license)
          allow(helper).to receive(:current_user).and_return(user)
          allow(helper).to receive(:signed_in?).and_return(true)
          allow(user).to receive(:can_admin_all_resources?).and_return(false)
        end

        it 'calls Gitlab::ExpiringSubscriptionMessage to get expiring message' do
          expect(Gitlab::ExpiringSubscriptionMessage).to receive(:new).with(
            subscribable: license,
            signed_in: true,
            is_admin: false,
            force_notification: false
          ).and_return(message_mock)

          expect(message_mock).to receive(:message)

          subject
        end
      end
    end

    context 'when instance variable false' do
      before do
        assign(:display_subscription_banner, false)
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      end

      it 'returns the license message' do
        expect(helper).to receive(:license_message).and_return(message)
        expect(subject).to eq(message)
      end
    end
  end

  describe '#display_subscription_banner!' do
    it 'sets @display_subscription_banner to true' do
      expect(helper.instance_variable_get(:@display_subscription_banner)).to be nil

      helper.display_subscription_banner!

      expect(helper.instance_variable_get(:@display_subscription_banner)).to be true
    end
  end

  describe '#link_to_button_style' do
    it 'return correct link with path and track property' do
      expect(link_to_button_style(path: '/subscriptions', track_property: 'test-track-label')).to match %r{<a.*href="/subscriptions".*>.*</a>}m
      expect(link_to_button_style(path: '/subscriptions', track_property: 'test-track-label')).to match %r{<a.*data-track-property="test-track-label".*>.*</a>}m
    end
  end
end
