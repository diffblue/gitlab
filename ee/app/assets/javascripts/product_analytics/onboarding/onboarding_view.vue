<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/flash';
import simplePoll from '~/lib/utils/simple_poll';
import initializeProductAnalyticsMutation from '../graphql/mutations/initialize_product_analytics.mutation.graphql';
import getProjectJitsuKeyQuery from '../graphql/mutations/get_project_jitsu_key.query.graphql';
import { hasAnalyticsData } from '../dashboards/data_sources/cube_analytics';
import {
  JITSU_KEY_CHECK_DELAY,
  CUBE_DATA_CHECK_DELAY,
  NO_INSTANCE_DATA,
  ONBOARDING_VIEW_I18N,
} from './constants';

export default {
  name: 'ProductAnalyticsOnboardingView',
  components: {
    GlLoadingIcon,
    OnboardingEmptyState: () => import('./components/onboarding_empty_state.vue'),
    OnboardingSetup: () => import('ee/product_analytics/onboarding/onboarding_setup.vue'),
  },
  inject: {
    projectFullPath: {
      type: String,
    },
    projectId: {
      type: String,
    },
  },
  props: {
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      creatingInstance: false,
      jitsuKey: null,
      pollJitsuKey: false,
      isLoading: false,
      showSetup: false,
    };
  },
  computed: {
    initializationIsLoading() {
      return this.creatingInstance || this.pollJitsuKey;
    },
  },
  async created() {
    if (this.status === NO_INSTANCE_DATA) {
      // For our first time polling, show loader
      // Afterwards, we can assume we are just polling in the background
      this.isLoading = true;
      this.showSetupView();
    }
  },
  apollo: {
    jitsuKey: {
      query: getProjectJitsuKeyQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      pollInterval: JITSU_KEY_CHECK_DELAY,
      update({ project }) {
        const { jitsuKey } = project || {};

        this.pollJitsuKey = !jitsuKey;

        return jitsuKey;
      },
      skip() {
        return !this.pollJitsuKey;
      },
      error(err) {
        this.showError(err);
        this.pollJitsuKey = false;
      },
    },
  },
  methods: {
    showError(error, captureError = true, message = '') {
      createAlert({
        message: message || error.message,
        captureError,
        error,
      });
    },
    showSetupView() {
      this.showSetup = true;
      this.pollForAnalyticsData();
    },
    async initializeProductAnalytics() {
      this.creatingInstance = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: initializeProductAnalyticsMutation,
          variables: {
            projectPath: this.projectFullPath,
          },
          context: {
            isSingleRequest: true,
          },
        });

        const [error] = data?.projectInitializeProductAnalytics?.errors || [];

        if (error) {
          this.showError(new Error(error), false);
        } else {
          this.pollJitsuKey = true;
          this.showSetupView();
        }
      } catch (err) {
        this.showError(err);
      } finally {
        this.creatingInstance = false;
      }
    },
    async fetchAnalyticsData(continuePoll, stopPoll) {
      try {
        const hasData = await hasAnalyticsData(this.projectId);

        if (hasData) {
          this.$emit('complete');
          stopPoll();
        } else {
          continuePoll();
        }
      } catch (error) {
        this.showError(error, true, this.$options.i18n.unhandledErrorMessage);

        this.$emit('error');
        stopPoll();
      } finally {
        this.isLoading = false;
      }
    },
    pollForAnalyticsData() {
      simplePoll((continuePoll, stopPoll) => this.fetchAnalyticsData(continuePoll, stopPoll), {
        interval: CUBE_DATA_CHECK_DELAY,
      }).catch(() => {
        this.pollForAnalyticsData();
      });
    },
  },
  i18n: ONBOARDING_VIEW_I18N,
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-7" />
  <onboarding-setup v-else-if="showSetup" />
  <onboarding-empty-state
    v-else
    :loading="initializationIsLoading"
    @initialize="initializeProductAnalytics"
  />
</template>
