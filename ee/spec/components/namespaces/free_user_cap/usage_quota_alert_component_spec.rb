# frozen_string_literal: true
require "spec_helper"

RSpec.describe Namespaces::FreeUserCap::UsageQuotaAlertComponent, :saas, type: :component do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user, refind: true) { create(:user) }
  let_it_be(:content_class) { '_content_class_' }

  let(:under_limit?) { false }
  let!(:gitlab_subscription) { create(:gitlab_subscription, :expired, namespace: namespace) }

  let(:title) do
    "Your free group is now limited to #{::Namespaces::FreeUserCap::FREE_USER_LIMIT} members"
  end

  let(:body) do
    'Your group recently changed to use the Free plan. Free groups are limited to 5 members and ' \
    'the remaining members will get a status of over-limit and lose access to the group. You can ' \
    'free up space for new members by removing those who no longer need access or toggling them ' \
    'to over-limit. To get an unlimited number of members, you can upgrade to a paid tier.'
  end

  subject(:component) { described_class.new(namespace: namespace, user: user, content_class: content_class) }

  before do
    allow_next_instance_of(::Namespaces::FreeUserCap::Standard) do |free_user_cap|
      allow(free_user_cap).to receive(:under_limit?).and_return(under_limit?)
    end

    namespace.add_owner(user)
  end

  shared_examples 'renders the alert' do
    it 'has the title' do
      render_inline(component)

      expect(rendered_component).to have_content(title)
    end
  end

  shared_examples 'does not render the alert' do
    it 'does not have the title' do
      render_inline(component)

      expect(rendered_component).not_to have_content(title)
    end
  end

  context 'when under limit' do
    let(:under_limit?) { true }

    it_behaves_like 'does not render the alert'
  end

  context 'when over limit' do
    context 'when paid subscription' do
      context 'when subscription is active' do
        let!(:gitlab_subscription) { create(:gitlab_subscription, namespace: namespace) }

        it_behaves_like 'does not render the alert'
      end

      context 'when subscription is expired' do
        context 'when is not on trial' do
          it 'has content for the alert' do
            render_inline(component)

            expect(rendered_component).to have_selector(".#{content_class}")
            expect(rendered_component).to have_content(title)
            expect(rendered_component).to have_content(body)
            expect(rendered_component).to have_link('upgrade', href: group_billings_path(namespace))

            expect(rendered_component)
              .to have_css('.js-user-over-limit-free-plan-alert' \
                             "[data-dismiss-endpoint='#{group_callouts_path}']" \
                             "[data-feature-id='#{described_class::FREE_GROUP_LIMITED_ALERT}']" \
                             "[data-group-id='#{namespace.id}']")
          end

          it 'renders all the expected tracking items' do
            render_inline(component)

            expect(rendered_component).to have_css('[data-testid="free-group-limited-alert"]' \
                                                     '[data-track-action="render"]' \
                                                     '[data-track-property="free_group_limited_usage_quota_banner"]')
            expect(rendered_component).to have_css('[data-testid="free-group-limited-dismiss"]' \
                                                     '[data-track-action="dismiss_banner"]' \
                                                     '[data-track-property="free_group_limited_usage_quota_banner"]')
            expect(rendered_component).to have_css('[data-track-action="click_link"]' \
                                                     '[data-track-label="upgrade"]' \
                                                     '[data-track-property="free_group_limited_usage_quota_banner"]')
          end
        end

        context 'when on trial' do
          let!(:gitlab_subscription) do
            create(:gitlab_subscription, :expired, :active_trial, namespace: namespace)
          end

          it_behaves_like 'does not render the alert'
        end
      end
    end

    context 'when free subscription' do
      context 'when trial is expired' do
        let!(:gitlab_subscription) { create(:gitlab_subscription, :expired_trial, :free, namespace: namespace) }

        it_behaves_like 'renders the alert'
      end

      context 'when trial is active' do
        let!(:gitlab_subscription) { create(:gitlab_subscription, :active_trial, :free, namespace: namespace) }

        it_behaves_like 'does not render the alert'
      end
    end
  end
end
