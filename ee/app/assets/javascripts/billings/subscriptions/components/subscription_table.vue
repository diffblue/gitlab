<script>
import { GlButton, GlCard, GlLoadingIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import { TABLE_TYPE_DEFAULT, TABLE_TYPE_FREE, TABLE_TYPE_TRIAL } from 'ee/billings/constants';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getSubscriptionData } from '../subscription_actions.customer.query.graphql';
import SubscriptionTableRow from './subscription_table_row.vue';

const createButtonProps = (text, href, testId) => ({ text, href, testId });

export default {
  name: 'SubscriptionTable',
  components: {
    GlButton,
    GlCard,
    GlLoadingIcon,
    SubscriptionTableRow,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    planRenewHref: {
      default: '',
    },
    namespaceId: {
      default: null,
    },
    customerPortalUrl: {
      default: '',
    },
    namespaceName: {
      default: '',
    },
    addSeatsHref: {
      default: '',
    },
    planName: {
      default: '',
    },
    refreshSeatsHref: {
      default: '',
    },
    readOnly: {
      default: false,
    },
  },
  data() {
    return {
      subscription: null,
    };
  },
  apollo: {
    subscription: {
      query: getSubscriptionData,
      variables() {
        return {
          namespaceId: this.namespaceId,
        };
      },
      skip() {
        return this.isFreePlan;
      },
    },
  },
  computed: {
    ...mapState(['isLoadingSubscription', 'hasErrorSubscription', 'plan', 'tables', 'endpoint']),
    ...mapGetters(['isFreePlan']),
    isSubscription() {
      return !this.isFreePlan;
    },
    subscriptionHeader() {
      const planName = this.isFreePlan ? s__('SubscriptionTable|Free') : this.escapedPlanName;
      const suffix = this.isSubscription && this.plan.trial ? s__('SubscriptionTable|Trial') : '';

      return `${this.namespaceName}: ${planName} ${suffix}`;
    },
    escapedPlanName() {
      if (!this.planName) {
        return '';
      }
      return escape(removeTrialSuffix(this.planName));
    },
    canRefreshSeats() {
      return this.glFeatures.refreshBillingsSeats;
    },
    addSeatsButton() {
      return this.isSubscription && this.subscription?.canAddSeats
        ? createButtonProps(
            s__('SubscriptionTable|Add seats'),
            this.addSeatsHref,
            'add-seats-button',
          )
        : null;
    },
    renewButton() {
      return this.subscription?.canRenew
        ? createButtonProps(s__('SubscriptionTable|Renew'), this.planRenewHref, 'renew-button')
        : null;
    },
    manageButton() {
      return this.isSubscription
        ? createButtonProps(
            s__('SubscriptionTable|Manage'),
            this.customerPortalUrl,
            'manage-button',
          )
        : null;
    },
    buttons() {
      return [this.addSeatsButton, this.renewButton, this.manageButton].filter(Boolean);
    },
    visibleRows() {
      let tableKey = TABLE_TYPE_DEFAULT;

      if (this.plan.code === null) {
        tableKey = TABLE_TYPE_FREE;
      } else if (this.plan.trial) {
        tableKey = TABLE_TYPE_TRIAL;
      }

      return this.tables[tableKey].rows;
    },
    isLoading() {
      return this.isLoadingSubscription || this.$apollo.loading;
    },
  },
  created() {
    this.fetchSubscription();
  },
  methods: {
    ...mapActions(['fetchSubscription']),
    isLast(index) {
      return index === this.visibleRows.length - 1;
    },
    async refreshSeats() {
      try {
        await axios.post(this.refreshSeatsHref);

        this.fetchSubscription();
      } catch (error) {
        createAlert({
          message: s__('SubscriptionTable|Something went wrong trying to refresh seats'),
          captureError: true,
          error,
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-card
      v-if="!isLoading && !hasErrorSubscription"
      class="gl-mt-3 subscription-table js-subscription-table"
      body-class="gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row gl-lg-flex-direction-column! flex-grid gl-p-0"
      header-class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <template #header>
        <strong data-testid="subscription-header" data-qa-selector="subscription_header">{{
          subscriptionHeader
        }}</strong>
        <div v-if="!readOnly" class="gl-display-flex">
          <gl-button
            v-for="(button, index) in buttons"
            :key="button.text"
            :href="button.href"
            :class="{ 'gl-ml-3': index !== 0 }"
            :data-testid="button.testId"
            category="secondary"
            target="_blank"
            variant="confirm"
            >{{ button.text }}</gl-button
          >
          <gl-button
            v-if="canRefreshSeats"
            :class="{ 'gl-ml-2': buttons.length !== 0 }"
            data-testid="refresh-seats-button"
            data-qa-selector="refresh_seats"
            category="secondary"
            variant="confirm"
            @click="refreshSeats"
            >{{ s__('SubscriptionTable|Refresh Seats') }}</gl-button
          >
        </div>
      </template>

      <subscription-table-row
        v-for="(row, i) in visibleRows"
        :key="`subscription-rows-${i}`"
        :last="isLast(i)"
        :header="row.header"
        :columns="row.columns"
        :is-free-plan="isFreePlan"
      />
    </gl-card>

    <gl-loading-icon
      v-else-if="isLoading && !hasErrorSubscription"
      :label="s__('SubscriptionTable|Loading subscriptions')"
      size="lg"
      class="gl-mt-3 gl-mb-3"
    />
  </div>
</template>
