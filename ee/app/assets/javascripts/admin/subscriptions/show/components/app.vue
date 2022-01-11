<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { isInFuture } from '~/lib/utils/datetime/date_calculation_utility';
import { sprintf } from '~/locale';
import {
  activateSubscription,
  noActiveSubscription,
  subscriptionActivationNotificationText,
  subscriptionActivationFutureDatedNotificationTitle,
  subscriptionActivationFutureDatedNotificationMessage,
  subscriptionHistoryQueries,
  subscriptionMainTitle,
  subscriptionQueries,
  exportLicenseUsageBtnText,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from '../constants';
import SubscriptionActivationCard from './subscription_activation_card.vue';
import SubscriptionBreakdown from './subscription_breakdown.vue';
import SubscriptionPurchaseCard from './subscription_purchase_card.vue';
import SubscriptionTrialCard from './subscription_trial_card.vue';

export default {
  name: 'CloudLicenseApp',
  components: {
    GlAlert,
    GlButton,
    SubscriptionActivationCard,
    SubscriptionBreakdown,
    SubscriptionPurchaseCard,
    SubscriptionTrialCard,
  },
  i18n: {
    activateSubscription,
    exportLicenseUsageBtnText,
    noActiveSubscription,
    subscriptionMainTitle,
  },
  props: {
    licenseUsageFilePath: {
      type: String,
      required: true,
    },
    hasActiveLicense: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  apollo: {
    currentSubscription: {
      query: subscriptionQueries.query,
      update({ currentLicense }) {
        return currentLicense || {};
      },
    },
    subscriptionHistory: {
      query: subscriptionHistoryQueries.query,
      update({ licenseHistoryEntries }) {
        return licenseHistoryEntries.nodes || [];
      },
    },
  },
  data() {
    return {
      currentSubscription: {},
      activationNotification: null,
      subscriptionHistory: [],
    };
  },
  computed: {
    hasValidSubscriptionData() {
      return Boolean(Object.keys(this.currentSubscription).length);
    },
    canShowSubscriptionDetails() {
      return this.hasActiveLicense || this.hasValidSubscriptionData;
    },
  },
  created() {
    this.$options.activationListeners = {
      [SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT]: this.displayActivationNotification,
    };
  },
  methods: {
    displayActivationNotification(license) {
      if (isInFuture(new Date(license.startsAt))) {
        this.activationNotification = {
          title: subscriptionActivationFutureDatedNotificationTitle,
          message: sprintf(subscriptionActivationFutureDatedNotificationMessage, {
            date: license.startsAt,
          }),
        };
      } else {
        this.activationNotification = { title: subscriptionActivationNotificationText };
      }
    },
    dismissActivationNotification() {
      this.activationNotification = null;
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-flex gl-flex-direction-row gl-justify-content-space-between gl-align-items-center"
    >
      <h4 data-testid="subscription-main-title">{{ $options.i18n.subscriptionMainTitle }}</h4>
      <gl-button v-if="canShowSubscriptionDetails" :href="licenseUsageFilePath">{{
        $options.i18n.exportLicenseUsageBtnText
      }}</gl-button>
    </div>
    <hr />
    <gl-alert
      v-if="activationNotification"
      variant="success"
      :title="activationNotification.title"
      class="gl-mb-6"
      data-testid="subscription-activation-success-alert"
      @dismiss="dismissActivationNotification"
    >
      {{ activationNotification.message }}
    </gl-alert>
    <subscription-breakdown
      v-if="canShowSubscriptionDetails"
      :subscription="currentSubscription"
      :subscription-list="subscriptionHistory"
      v-on="$options.activationListeners"
    />
    <div v-else class="row">
      <div class="col-12">
        <h3 class="gl-mb-7 gl-mt-6 gl-text-center" data-testid="subscription-activation-title">
          {{ $options.i18n.noActiveSubscription }}
        </h3>
        <subscription-activation-card v-on="$options.activationListeners" />
        <div class="row gl-mt-7">
          <div class="col-lg-6">
            <subscription-trial-card />
          </div>
          <div class="col-lg-6">
            <subscription-purchase-card />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
