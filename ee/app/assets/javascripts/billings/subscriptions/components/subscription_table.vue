<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import { removeTrialSuffix } from 'ee/billings/billings_util';
import {
  TABLE_TYPE_DEFAULT,
  TABLE_TYPE_FREE,
  TABLE_TYPE_TRIAL,
  DAYS_FOR_RENEWAL,
} from 'ee/billings/constants';
import ExtendReactivateTrialButton from 'ee/trials/extend_reactivate_trial/components/extend_reactivate_trial_button.vue';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { getDayDifference } from '~/lib/utils/datetime/date_calculation_utility';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SubscriptionTableRow from './subscription_table_row.vue';

const createButtonProps = (text, href, testId) => ({ text, href, testId });

export default {
  name: 'SubscriptionTable',
  components: {
    GlButton,
    GlLoadingIcon,
    SubscriptionTableRow,
    ExtendReactivateTrialButton,
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
    availableTrialAction: {
      default: null,
    },
    trialPlanName: {
      default: '',
    },
  },
  computed: {
    ...mapState([
      'isLoadingSubscription',
      'hasErrorSubscription',
      'plan',
      'billing',
      'tables',
      'endpoint',
    ]),
    ...mapGetters(['isFreePlan']),
    isSubscription() {
      return !this.isFreePlan;
    },
    subscriptionHeader() {
      const planName = this.isFreePlan
        ? s__('SubscriptionTable|Free')
        : escape(removeTrialSuffix(this.planName));
      const suffix = this.isSubscription && this.plan.trial ? s__('SubscriptionTable|Trial') : '';

      return `${this.namespaceName}: ${planName} ${suffix}`;
    },
    canRefreshSeats() {
      return this.glFeatures.refreshBillingsSeats;
    },
    canRenew() {
      const subscriptionEndDate = new Date(this.billing.subscriptionEndDate);
      const todayDate = new Date();
      return (
        this.isSubscription &&
        !this.plan.trial &&
        DAYS_FOR_RENEWAL >= getDayDifference(todayDate, subscriptionEndDate)
      );
    },
    addSeatsButton() {
      return this.isSubscription
        ? createButtonProps(
            s__('SubscriptionTable|Add seats'),
            this.addSeatsHref,
            'add-seats-button',
          )
        : null;
    },
    renewButton() {
      return this.canRenew
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
        createFlash({
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
    <div
      v-if="!isLoadingSubscription && !hasErrorSubscription"
      class="gl-card gl-mt-3 subscription-table js-subscription-table"
    >
      <div
        class="gl-card-header gl-display-flex gl-justify-content-space-between gl-align-items-center"
        data-testid="subscription-header"
      >
        <strong data-qa-selector="subscription_header">{{ subscriptionHeader }}</strong>
        <div class="gl-display-flex">
          <extend-reactivate-trial-button
            v-if="availableTrialAction"
            :namespace-id="namespaceId"
            :action="availableTrialAction"
            :plan-name="trialPlanName"
            class="gl-mr-3"
          />
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
      </div>
      <div
        class="gl-card-body gl-display-flex gl-flex-direction-column gl-sm-flex-direction-row flex-lg-column flex-grid gl-p-0"
      >
        <subscription-table-row
          v-for="(row, i) in visibleRows"
          :key="`subscription-rows-${i}`"
          :last="isLast(i)"
          :header="row.header"
          :columns="row.columns"
          :is-free-plan="isFreePlan"
        />
      </div>
    </div>

    <gl-loading-icon
      v-else-if="isLoadingSubscription && !hasErrorSubscription"
      :label="s__('SubscriptionTable|Loading subscriptions')"
      size="lg"
      class="gl-mt-3 gl-mb-3"
    />
  </div>
</template>
