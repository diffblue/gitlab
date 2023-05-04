<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import OnboardingState from './components/onboarding_state.vue';
import {
  STATE_LOADING_INSTANCE,
  STATE_CREATE_INSTANCE,
  STATE_WAITING_FOR_EVENTS,
  FETCH_ERROR_MESSAGE,
} from './constants';

export default {
  name: 'ProductAnalyticsOnboardingView',
  components: {
    GlLoadingIcon,
    OnboardingState,
    OnboardingEmptyState: () => import('./components/onboarding_empty_state.vue'),
    OnboardingSetup: () => import('ee/product_analytics/onboarding/onboarding_setup.vue'),
  },
  data() {
    return {
      state: '',
      pollState: false,
    };
  },
  computed: {
    loadingInstance() {
      return this.state === STATE_LOADING_INSTANCE;
    },
    showEmptyState() {
      return this.state === STATE_CREATE_INSTANCE || this.loadingInstance;
    },
    showSetup() {
      return this.state === STATE_WAITING_FOR_EVENTS;
    },
  },
  methods: {
    onComplete() {
      this.$router.push({ name: 'index' });
    },
    onInitialized() {
      this.pollState = true;
    },
    showError(error, captureError = true, message = '') {
      createAlert({
        message: message || error.message,
        captureError,
        error,
      });
    },
  },
  i18n: {
    fetchErrorMessage: FETCH_ERROR_MESSAGE,
  },
};
</script>

<template>
  <div>
    <onboarding-state
      v-model="state"
      :poll-state="pollState"
      @complete="onComplete"
      @error="showError($event, false, $options.i18n.fetchErrorMessage)"
    />

    <gl-loading-icon v-if="!state" size="lg" class="gl-my-7" />

    <onboarding-empty-state
      v-else-if="showEmptyState"
      :loading-instance="loadingInstance"
      @initialized="onInitialized"
      @error="showError($event)"
    />

    <onboarding-setup v-else-if="showSetup" is-initial-setup />
  </div>
</template>
