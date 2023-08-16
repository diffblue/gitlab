<script>
import { s__ } from '~/locale';
import AnalyticsFeatureListItem from 'ee/analytics/analytics_dashboards/components/list/feature_list_item.vue';
import { STATE_COMPLETE, STATE_WAITING_FOR_EVENTS, STATE_LOADING_INSTANCE } from '../constants';

import OnboardingState from './onboarding_state.vue';

export default {
  name: 'ProductAnalyticsOnboardingListItem',
  components: {
    OnboardingState,
    AnalyticsFeatureListItem,
  },
  data() {
    return {
      state: '',
    };
  },
  computed: {
    needsSetup() {
      return this.state && this.state !== STATE_COMPLETE;
    },
    badgeText() {
      switch (this.state) {
        case STATE_WAITING_FOR_EVENTS:
          return s__('ProductAnalytics|Waiting for events');
        case STATE_LOADING_INSTANCE:
          return s__('ProductAnalytics|Loading instance');
        default:
          return null;
      }
    },
  },
  methods: {
    onError(error) {
      this.$emit(
        'error',
        error,
        true,
        s__(
          'ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.',
        ),
      );
    },
  },
  onboardingRoute: 'product-analytics-onboarding',
};
</script>

<template>
  <onboarding-state v-model="state" @complete="$emit('complete')" @error="onError">
    <analytics-feature-list-item
      v-if="needsSetup"
      :title="__('Product Analytics')"
      :description="
        s__(
          'ProductAnalytics|Set up to track how your product is performing and optimize your product and development processes.',
        )
      "
      :badge-text="badgeText"
      :to="$options.onboardingRoute"
    />
  </onboarding-state>
</template>
