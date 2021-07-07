<script>
import emptySvg from '@gitlab/svgs/dist/illustrations/security-dashboard-empty-state.svg';
import { GlEmptyState } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import { ERROR_FETCHING_DATA_HEADER, ERROR_FETCHING_DATA_DESCRIPTION } from '~/ensure_data';
import plansQuery from '../../graphql/queries/plans.customer.query.graphql';
import { planTags, CUSTOMER_CLIENT } from '../constants';
import Checkout from './checkout.vue';
import OrderSummary from './order_summary.vue';

export default {
  components: {
    Checkout,
    GlEmptyState,
    OrderSummary,
    StepOrderApp,
  },
  i18n: {
    ERROR_FETCHING_DATA_HEADER,
    ERROR_FETCHING_DATA_DESCRIPTION,
  },
  emptySvg,
  data() {
    return {
      hasError: false,
    };
  },
  apollo: {
    plans: {
      client: CUSTOMER_CLIENT,
      query: plansQuery,
      variables: {
        tags: [planTags.CI_1000_MINUTES_PLAN],
      },
      update(data) {
        if (!data?.plans?.length) {
          this.hasError = true;
          return null;
        }

        return data.plans;
      },
      error(error) {
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
  },
};
</script>
<template>
  <gl-empty-state
    v-if="hasError"
    :title="$options.i18n.ERROR_FETCHING_DATA_HEADER"
    :description="$options.i18n.ERROR_FETCHING_DATA_DESCRIPTION"
    :svg-path="`data:image/svg+xml;utf8,${encodeURIComponent($options.emptySvg)}`"
  />
  <step-order-app v-else-if="!$apollo.loading">
    <template #checkout>
      <checkout :plan="plans[0]" />
    </template>
    <template #order-summary>
      <order-summary :plan="plans[0]" />
    </template>
  </step-order-app>
</template>
