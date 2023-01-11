<script>
import { createAlert } from '~/flash';
import initializeProductAnalyticsMutation from '../graphql/mutations/initialize_product_analytics.mutation.graphql';
import getProjectJitsuKeyQuery from '../graphql/mutations/get_project_jitsu_key.query.graphql';
import OnboardingEmptyState from './components/onboarding_empty_state.vue';
import { JITSU_KEY_CHECK_DELAY } from './constants';

export default {
  name: 'ProductAnalyticsOnboardingView',
  components: {
    OnboardingEmptyState,
  },
  inject: {
    projectFullPath: {
      type: String,
    },
  },
  data() {
    return {
      creatingInstance: false,
      jitsuKey: null,
      pollJitsuKey: false,
    };
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
  computed: {
    loading() {
      return this.creatingInstance || this.pollJitsuKey;
    },
  },
  methods: {
    showError(error, captureError = true) {
      createAlert({
        message: error.message,
        captureError,
        error,
      });
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
        }
      } catch (err) {
        // TODO: Update to show the tracking codes view when no error in https://gitlab.com/gitlab-org/gitlab/-/issues/381320
        this.showError(err);
      } finally {
        this.creatingInstance = false;
      }
    },
  },
};
</script>

<template>
  <onboarding-empty-state :loading="loading" @initialize="initializeProductAnalytics" />
</template>
