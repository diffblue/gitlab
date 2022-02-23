<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { minBy } from 'lodash';
import { isInFuture } from '~/lib/utils/datetime/date_calculation_utility';
import { instanceHasFutureLicenseBanner, noActiveSubscription } from '../constants';
import SubscriptionActivationCard from './subscription_activation_card.vue';
import SubscriptionDetailsHistory from './subscription_details_history.vue';
import SubscriptionPurchaseCard from './subscription_purchase_card.vue';
import SubscriptionTrialCard from './subscription_trial_card.vue';

export default {
  name: 'NoActiveSubscription',
  components: {
    GlAlert,
    GlSprintf,
    SubscriptionActivationCard,
    SubscriptionPurchaseCard,
    SubscriptionTrialCard,
    SubscriptionDetailsHistory,
  },
  i18n: {
    instanceHasFutureLicenseBanner,
    noActiveSubscription,
  },
  props: {
    subscriptionList: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasItems() {
      return Boolean(this.subscriptionList.length);
    },
    nextFutureDatedLicenseDate() {
      const futureItems = this.subscriptionList.filter((license) =>
        isInFuture(new Date(license.startsAt)),
      );
      const nextFutureDatedItem = minBy(futureItems, (license) => new Date(license.startsAt));
      return nextFutureDatedItem?.startsAt;
    },
    hasFutureDatedLicense() {
      return Boolean(this.nextFutureDatedLicenseDate);
    },
  },
};
</script>

<template>
  <div class="row">
    <div class="col-12">
      <h3 class="gl-mb-7 gl-mt-6 gl-text-center" data-testid="subscription-activation-title">
        {{ $options.i18n.noActiveSubscription }}
      </h3>
      <subscription-activation-card v-on="$listeners" />
      <gl-alert
        v-if="hasFutureDatedLicense"
        :title="$options.i18n.instanceHasFutureLicenseBanner.title"
        :dismissible="false"
        class="gl-mt-5"
        variant="info"
        data-testid="subscription-future-licenses-alert"
      >
        <gl-sprintf :message="$options.i18n.instanceHasFutureLicenseBanner.message">
          <template #date>{{ nextFutureDatedLicenseDate }}</template>
        </gl-sprintf>
      </gl-alert>
      <div v-if="hasItems && hasFutureDatedLicense" class="col-12 gl-mt-5">
        <subscription-details-history :subscription-list="subscriptionList" />
      </div>

      <div class="row gl-mt-7">
        <div class="col-lg-6 gl-sm-mb-7">
          <subscription-trial-card />
        </div>
        <div class="col-lg-6">
          <subscription-purchase-card />
        </div>
      </div>

      <div v-if="hasItems && !hasFutureDatedLicense" class="col-12 gl-mt-5">
        <subscription-details-history :subscription-list="subscriptionList" />
      </div>
    </div>
  </div>
</template>
