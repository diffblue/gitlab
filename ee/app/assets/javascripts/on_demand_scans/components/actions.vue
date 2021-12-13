<script>
import pipelineCancelMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import pipelineRetryMutation from '~/pipelines/graphql/mutations/retry_pipeline.mutation.graphql';
import { __, s__ } from '~/locale';
import {
  PIPELINES_GROUP_RUNNING,
  PIPELINES_GROUP_PENDING,
  PIPELINES_GROUP_SUCCESS_WITH_WARNINGS,
  PIPELINES_GROUP_FAILED,
} from '../constants';
import ActionButton from './action_button.vue';

const CANCELLING_PROPERTY = 'isCancelling';
const RETRYING_PROPERTY = 'isRetrying';

export const cancelError = s__('OnDemandScans|The scan could not be canceled.');
export const retryError = s__('OnDemandScans|The scan could not be retried.');

export default {
  components: {
    ActionButton,
  },
  props: {
    scan: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      [CANCELLING_PROPERTY]: false,
      [RETRYING_PROPERTY]: false,
    };
  },
  computed: {
    isCancellable() {
      return [PIPELINES_GROUP_RUNNING, PIPELINES_GROUP_PENDING].includes(
        this.scan?.detailedStatus?.group,
      );
    },
    isRetryable() {
      return [PIPELINES_GROUP_SUCCESS_WITH_WARNINGS, PIPELINES_GROUP_FAILED].includes(
        this.scan?.detailedStatus?.group,
      );
    },
  },
  watch: {
    'scan.detailedStatus.group': function detailedStatusGroupWatcher() {
      this[CANCELLING_PROPERTY] = false;
      this[RETRYING_PROPERTY] = false;
    },
  },
  methods: {
    action({ loadingProperty, mutation, mutationType, defaultErrorMessage }) {
      this.$emit('action');
      this[loadingProperty] = true;
      this.$apollo
        .mutate({
          mutation,
          variables: {
            id: this.scan.id,
          },
          update: (_store, { data = {} }) => {
            const [errorMessage] = data[mutationType]?.errors ?? [];

            if (errorMessage) {
              this.triggerError(loadingProperty, errorMessage);
            }
          },
        })
        .catch((exception) => {
          this.triggerError(loadingProperty, defaultErrorMessage, exception);
        });
    },
    cancelPipeline() {
      this.action({
        loadingProperty: CANCELLING_PROPERTY,
        mutation: pipelineCancelMutation,
        mutationType: 'pipelineCancel',
        defaultErrorMessage: this.$options.i18n.cancelError,
      });
    },
    retryPipeline() {
      this.action({
        loadingProperty: RETRYING_PROPERTY,
        mutation: pipelineRetryMutation,
        mutationType: 'pipelineRetry',
        defaultErrorMessage: this.$options.i18n.retryError,
      });
    },
    triggerError(loadingProperty, message, exception) {
      this[loadingProperty] = false;
      this.$emit('error', message, exception);
    },
  },
  i18n: {
    cancel: __('Cancel'),
    cancelError,
    retry: __('Retry'),
    retryError,
  },
};
</script>

<template>
  <div class="gl-text-right">
    <ActionButton
      v-if="isCancellable"
      data-testid="cancel-scan-button"
      action-type="cancel"
      :label="$options.i18n.cancel"
      :is-loading="isCancelling"
      @click="cancelPipeline"
    />
    <ActionButton
      v-if="isRetryable"
      data-testid="retry-scan-button"
      action-type="retry"
      :label="$options.i18n.retry"
      :is-loading="isRetrying"
      @click="retryPipeline"
    />
  </div>
</template>
