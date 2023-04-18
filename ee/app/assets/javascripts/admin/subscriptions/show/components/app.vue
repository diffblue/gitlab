<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { isInFuture } from '~/lib/utils/datetime/date_calculation_utility';
import { sprintf } from '~/locale';
import {
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
  customersPortalBtnText,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from '../constants';
import getCurrentLicense from '../graphql/queries/get_current_license.query.graphql';
import getPastLicenseHistory from '../graphql/queries/get_past_license_history.query.graphql';
import getFutureLicenseHistory from '../graphql/queries/get_future_license_history.query.graphql';
import SubscriptionBreakdown from './subscription_breakdown.vue';
import NoActiveSubscription from './no_active_subscription.vue';

export default {
  name: 'CloudLicenseApp',
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
    SubscriptionBreakdown,
    NoActiveSubscription,
  },
  inject: ['customersPortalUrl'],
  i18n: {
    exportLicenseUsageBtnText,
    customersPortalBtnText,
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
      this.$apollo.queries.currentSubscription.refetch();
      this.$apollo.queries.pastLicenseHistoryEntries.refetch();
      this.$apollo.queries.futureLicenseHistoryEntries.refetch();
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
      class="gl-display-flex gl-flex-direction-row gl-justify-content-space-between gl-align-items-center gl-flex-wrap"
    >
      <h4 data-testid="subscription-main-title" class="gl-w-full gl-sm-w-auto">
        {{ $options.i18n.subscriptionMainTitle }}
      </h4>
      <gl-button
        v-if="canShowSubscriptionDetails"
        class="gl-ml-auto gl-mr-3"
        data-testid="export-license-usage-btn"
        :href="licenseUsageFilePath"
        >{{ $options.i18n.exportLicenseUsageBtnText }}
      </gl-button>
      <gl-button
        category="secondary"
        variant="confirm"
        icon="external-link"
        target="_blank"
        data-testid="customers-portal-btn"
        :href="customersPortalUrl"
        >{{ $options.i18n.customersPortalBtnText }}
      </gl-button>
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
    <no-active-subscription
      v-else
      :subscription-list="subscriptionHistory"
      v-on="$options.activationListeners"
    />
  </div>
</template>
