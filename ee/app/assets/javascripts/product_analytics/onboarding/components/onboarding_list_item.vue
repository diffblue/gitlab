<script>
import AnalyticsFeatureListItem from 'ee/analytics/analytics_dashboards/components/list/feature_list_item.vue';
import {
  STATE_COMPLETE,
  STATE_WAITING_FOR_EVENTS,
  STATE_LOADING_INSTANCE,
  ONBOARDING_LIST_ITEM_I18N,
  FETCH_ERROR_MESSAGE,
} from '../constants';

import OnboardingState from './onboarding_state.vue';

export default {
  name: 'ProductAnalyticsOnboardingListItem',
  components: {
    OnboardingState,
    AnalyticsFeatureListItem,
  },
  inject: {
    projectFullPath: {
      type: String,
    },
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
          return ONBOARDING_LIST_ITEM_I18N.waitingForEvents;
        case STATE_LOADING_INSTANCE:
          return ONBOARDING_LIST_ITEM_I18N.loadingInstance;
        default:
          return null;
      }
    },
  },
  methods: {
    onError(error) {
      this.$emit('error', error, true, FETCH_ERROR_MESSAGE);
    },
  },
  i18n: ONBOARDING_LIST_ITEM_I18N,
  onboardingRoute: 'product-analytics-onboarding',
};
</script>

<template>
  <onboarding-state v-model="state" @complete="$emit('complete')" @error="onError">
    <analytics-feature-list-item
      v-if="needsSetup"
      :title="$options.i18n.title"
      :description="$options.i18n.description"
      :badge-text="badgeText"
      :to="$options.onboardingRoute"
    />
  </onboarding-state>
</template>
