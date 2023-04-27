<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, n__, __ } from '~/locale';

export const billableUsersURL = helpPagePath('subscriptions/self_managed/index', {
  anchor: 'billable-users',
});
export const trueUpURL =
  'https://about.gitlab.com/pricing/licensing-faq/#what-does-users-over-license-mean';

export const usersInSubscriptionUnlimited = __('Unlimited');

export const i18n = Object.freeze({
  billableUsersTitle: s__('SuperSonics|Billable users'),
  maximumUsersTitle: s__('SuperSonics|Maximum users'),
  usersOverSubscriptionTitle: s__('SuperSonics|Users over subscription'),
  billableUsersText: s__(
    'SuperSonics|This is the number of %{billableUsersLinkStart}billable users%{billableUsersLinkEnd} on your installation, and this is the minimum number you need to purchase when you renew your license.',
  ),
  maximumUsersText: s__(
    'SuperSonics|This is the highest peak of users on your installation since the license started.',
  ),
  usersInSubscriptionText: s__(
    `SuperSonics|Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license.`,
  ),
  usersOverSubscriptionText: s__(
    `SuperSonics|You'll be charged for %{trueUpLinkStart}users over license%{trueUpLinkEnd} on a quarterly or annual basis, depending on the terms of your agreement.`,
  ),
});

export default {
  links: {
    billableUsersURL,
    trueUpURL,
  },
  name: 'SubscriptionDetailsUserInfo',
  components: {
    GlCard,
    GlLink,
    GlSprintf,
  },
  props: {
    subscription: {
      type: Object,
      required: true,
    },
  },
  computed: {
    usersInSubscription() {
      return this.subscription.usersInLicenseCount ?? usersInSubscriptionUnlimited;
    },
    billableUsers() {
      return this.subscription.billableUsersCount;
    },
    maximumUsers() {
      return this.subscription.maximumUserCount;
    },
    usersOverSubscription() {
      return this.subscription.usersOverLicenseCount;
    },
    isUsersInSubscriptionVisible() {
      return this.subscription.plan === 'ultimate';
    },
    usersInSubscriptionTitle() {
      if (this.subscription.usersInLicenseCount) {
        return n__(
          'SuperSonics|User in subscription',
          'SuperSonics|Users in subscription',
          this.subscription.usersInLicenseCount,
        );
      }

      return s__('SuperSonics|Users in subscription');
    },
  },
  i18n,
};
</script>

<template>
  <section class="row">
    <div class="col-md-6 gl-mb-5">
      <gl-card class="gl-h-full" data-testid="users-in-subscription">
        <header>
          <h2 data-qa-selector="users_in_subscription">{{ usersInSubscription }}</h2>
          <h5 class="gl-font-weight-normal text-uppercase">{{ usersInSubscriptionTitle }}</h5>
        </header>
        <p v-if="isUsersInSubscriptionVisible" data-testid="users-in-subscription-desc">
          {{ $options.i18n.usersInSubscriptionText }}
        </p>
      </gl-card>
    </div>

    <div class="col-md-6 gl-mb-5">
      <gl-card class="gl-h-full" data-testid="billable-users">
        <header>
          <h2 data-qa-selector="billable_users">{{ billableUsers }}</h2>
          <h5 class="gl-font-weight-normal text-uppercase">
            {{ $options.i18n.billableUsersTitle }}
          </h5>
        </header>
        <p>
          <gl-sprintf :message="$options.i18n.billableUsersText">
            <template #billableUsersLink="{ content }">
              <gl-link :href="$options.links.billableUsersURL" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-card>
    </div>

    <div class="col-md-6 gl-mb-5">
      <gl-card class="gl-h-full" data-testid="maximum-users">
        <header>
          <h2 data-qa-selector="maximum_users">{{ maximumUsers }}</h2>
          <h5 class="gl-font-weight-normal text-uppercase">
            {{ $options.i18n.maximumUsersTitle }}
          </h5>
        </header>
        <p>{{ $options.i18n.maximumUsersText }}</p>
      </gl-card>
    </div>

    <div class="col-md-6 gl-mb-5">
      <gl-card class="gl-h-full" data-testid="users-over-license">
        <header>
          <h2 data-qa-selector="users_over_subscription">{{ usersOverSubscription }}</h2>
          <h5 class="gl-font-weight-normal text-uppercase">
            {{ $options.i18n.usersOverSubscriptionTitle }}
          </h5>
        </header>
        <p>
          <gl-sprintf :message="$options.i18n.usersOverSubscriptionText">
            <template #trueUpLink="{ content }">
              <gl-link :href="$options.links.trueUpURL">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-card>
    </div>
  </section>
</template>
