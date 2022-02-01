<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { isInFuture } from '~/lib/utils/datetime/date_calculation_utility';
import { sprintf } from '~/locale';
import {
  activateSubscription,
  noActiveSubscription,
  subscriptionActivationNotificationText,
  subscriptionActivationFutureDatedNotificationTitle,
  subscriptionActivationFutureDatedNotificationMessage,
  subscriptionHistoryFailedTitle,
  subscriptionHistoryFailedMessage,
  currentSubscriptionsEntryName,
  pastSubscriptionsEntryName,
  futureSubscriptionsEntryName,
  subscriptionMainTitle,
  exportLicenseUsageBtnText,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from '../constants';
import getCurrentLicense from '../graphql/queries/get_current_license.query.graphql';
import getPastLicenseHistory from '../graphql/queries/get_past_license_history.query.graphql';
import getFutureLicenseHistory from '../graphql/queries/get_future_license_history.query.graphql';
import SubscriptionActivationCard from './subscription_activation_card.vue';
import SubscriptionBreakdown from './subscription_breakdown.vue';
import SubscriptionPurchaseCard from './subscription_purchase_card.vue';
import SubscriptionTrialCard from './subscription_trial_card.vue';

export default {
  name: 'CloudLicenseApp',
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
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
    subscriptionHistoryFailedTitle,
    subscriptionHistoryFailedMessage,
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
      query: getCurrentLicense,
      update({ currentLicense }) {
        return currentLicense || {};
      },
      error() {
        this.subscriptionFetchError = currentSubscriptionsEntryName;
      },
    },
    pastLicenseHistoryEntries: {
      query: getPastLicenseHistory,
      update({ licenseHistoryEntries }) {
        return licenseHistoryEntries?.nodes || [];
      },
      error() {
        this.subscriptionFetchError = pastSubscriptionsEntryName;
      },
    },
    futureLicenseHistoryEntries: {
      query: getFutureLicenseHistory,
      update({ subscriptionFutureEntries }) {
        return subscriptionFutureEntries?.nodes || [];
      },
      error() {
        this.subscriptionFetchError = futureSubscriptionsEntryName;
      },
    },
  },
  data() {
    return {
      currentSubscription: {},
      pastLicenseHistoryEntries: [],
      futureLicenseHistoryEntries: [],
      activationNotification: null,
      subscriptionFetchError: null,
    };
  },
  computed: {
    hasValidSubscriptionData() {
      return Boolean(Object.keys(this.currentSubscription).length);
    },
    canShowSubscriptionDetails() {
      return this.hasActiveLicense || this.hasValidSubscriptionData;
    },
    subscriptionHistory() {
      return [...this.futureLicenseHistoryEntries, ...this.pastLicenseHistoryEntries];
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
    dismissSubscriptionFetchError() {
      this.subscriptionFetchError = null;
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
    <gl-alert
      v-if="subscriptionFetchError"
      :title="$options.i18n.subscriptionHistoryFailedTitle"
      variant="danger"
      class="gl-mb-6"
      data-testid="subscription-fetch-error-alert"
      @dismiss="dismissSubscriptionFetchError"
    >
      <gl-sprintf :message="$options.i18n.subscriptionHistoryFailedMessage">
        <template #subscriptionEntryName>
          {{ subscriptionFetchError }}
        </template>
      </gl-sprintf>
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
