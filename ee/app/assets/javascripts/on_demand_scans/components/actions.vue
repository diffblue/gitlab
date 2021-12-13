<script>
import { GlButton, GlTooltip } from '@gitlab/ui';
import pipelineCancelMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import { __, s__ } from '~/locale';
import { PIPELINES_GROUP_RUNNING, PIPELINES_GROUP_PENDING } from '../constants';

const CANCELLING_PROPERTY = 'isCancelling';

export const cancelError = s__('OnDemandScans|The scan could not be canceled.');

export default {
  components: {
    GlButton,
    GlTooltip,
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
    };
  },
  computed: {
    isCancellable() {
      return [PIPELINES_GROUP_RUNNING, PIPELINES_GROUP_PENDING].includes(
        this.scan?.detailedStatus?.group,
      );
    },
  },
  methods: {
    cancelPipeline() {
      this.$emit('action');
      this[CANCELLING_PROPERTY] = true;
      this.$apollo
        .mutate({
          mutation: pipelineCancelMutation,
          variables: {
            id: this.scan.id,
          },
          update: (_store, { data = {} }) => {
            const [errorMessage] = data.pipelineCancel?.errors ?? [];

            if (errorMessage) {
              this.triggerError(CANCELLING_PROPERTY, errorMessage);
            }
          },
        })
        .catch((exception) => {
          this.triggerError(CANCELLING_PROPERTY, this.$options.i18n.cancelError, exception);
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
  },
};
</script>

<template>
  <div class="gl-text-right">
    <template v-if="isCancellable">
      <gl-button
        :id="`cancel-button-${scan.id}`"
        :aria-label="$options.i18n.cancel"
        :loading="isCancelling"
        icon="cancel"
        data-testid="cancel-scan-button"
        @click="cancelPipeline"
      />
      <gl-tooltip
        :target="`cancel-button-${scan.id}`"
        placement="top"
        triggers="hover"
        noninteractive
      >
        {{ $options.i18n.cancel }}
      </gl-tooltip>
    </template>
  </div>
</template>
