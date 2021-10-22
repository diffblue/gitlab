<script>
import { GlButton } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { ERROR_RUN_SCAN, ERROR_MESSAGES } from 'ee/on_demand_scans_form/settings';
import { redirectTo } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import dastProfileRunMutation from '../graphql/dast_profile_run.mutation.graphql';
import ProfilesList from './dast_profiles_list.vue';
import DastScanBranch from './dast_scan_branch.vue';
import ScanSchedule from './dast_scan_schedule.vue';
import ScanTypeBadge from './dast_scan_type_badge.vue';

export default {
  components: {
    GlButton,
    ProfilesList,
    DastScanBranch,
    ScanSchedule,
    ScanTypeBadge,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    errorDetails: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      isRunningScan: null,
      hasRunScanError: false,
      runScanErrors: [],
    };
  },
  computed: {
    error() {
      if (this.hasRunScanError) {
        return {
          errorMessage: ERROR_MESSAGES[ERROR_RUN_SCAN],
          errorDetails: this.runScanErrors,
        };
      }
      const { errorMessage, errorDetails } = this;
      return { errorMessage, errorDetails };
    },
  },
  watch: {
    errorMessage() {
      this.hasRunScanError = false;
    },
  },
  methods: {
    async runScan({ id }) {
      this.isRunningScan = id;
      this.hasRunScanError = false;
      try {
        const {
          data: {
            dastProfileRun: { pipelineUrl, errors },
          },
        } = await this.$apollo.mutate({
          mutation: dastProfileRunMutation,
          variables: {
            input: {
              id,
            },
          },
        });

        if (errors.length) {
          this.handleRunScanError({ errors });
        } else {
          redirectTo(pipelineUrl);
        }
      } catch (error) {
        this.handleRunScanError(error);
      }
    },
    handleRunScanError({ exception = null, errors = [] } = {}) {
      this.isRunningScan = null;
      this.hasRunScanError = true;
      this.runScanErrors = errors;
      if (exception !== null) {
        Sentry.captureException(exception);
      }
    },
  },
};
</script>

<template>
  <profiles-list
    :error-message="error.errorMessage"
    :error-details="error.errorDetails"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #cell(name)="{ item: { name, branch, editPath } }">
      {{ name }}
      <dast-scan-branch :branch="branch" :edit-path="editPath" />
    </template>

    <!-- eslint-disable-next-line vue/valid-v-slot -->
    <template #cell(dastScannerProfile.scanType)="{ value }">
      <scan-type-badge :scan-type="value" />
    </template>

    <!-- eslint-disable-next-line vue/valid-v-slot -->
    <template #cell(dastProfileSchedule)="{ value }">
      <scan-schedule :schedule="value || null" />
    </template>

    <template #actions="{ profile }">
      <gl-button
        size="small"
        data-testid="dast-scan-run-button"
        :loading="isRunningScan === profile.id"
        :disabled="Boolean(isRunningScan)"
        @click="runScan(profile)"
        >{{ s__('DastProfiles|Run scan') }}</gl-button
      >
    </template>
  </profiles-list>
</template>
