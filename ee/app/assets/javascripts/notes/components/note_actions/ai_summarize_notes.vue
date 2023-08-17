<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import { MAX_REQUEST_TIMEOUT } from 'ee/notes/constants';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resourceGlobalId: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      errorAlert: null,
      aiCompletionResponse: {},
    };
  },
  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  },
  methods: {
    onClick() {
      this.hideTooltips();

      if (this.loading) {
        return;
      }

      this.errorAlert?.dismiss();

      this.$parent.$emit('set-ai-loading', true);
      this.timeout = window.setTimeout(this.handleError, MAX_REQUEST_TIMEOUT);

      this.$apollo
        .mutate({
          mutation: aiActionMutation,
          variables: { input: { summarizeComments: { resourceId: this.resourceGlobalId } } },
        })
        .then(({ data: { aiAction } }) => {
          const errors = aiAction?.errors || [];

          // in some cases the tooltip can get stuck
          // open when clicking the button, so hide again just in case
          this.hideTooltips();

          if (errors[0]) {
            this.handleError(new Error(errors[0]));
          }

          clearTimeout(this.timeout);
        })
        .catch(this.handleError);
    },
    hideTooltips() {
      this.$nextTick(() => {
        this.$root.$emit(BV_HIDE_TOOLTIP);
      });
    },
    handleError(error) {
      this.hideTooltips();
      const alertOptions = error ? { captureError: true, error } : {};
      this.errorAlert = createAlert({
        message: error ? error.message : __('Something went wrong'),
        ...alertOptions,
      });
      this.$parent.$emit('set-ai-loading', false);
    },
  },
  i18n: {
    button: s__('AISummary|View summary'),
    tooltip: s__('AISummary|Generates a summary of all comments'),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip
    icon="tanuki-ai"
    :disabled="loading"
    :loading="loading"
    :title="$options.i18n.tooltip"
    :aria-label="$options.i18n.tooltip"
    @click="onClick"
    @mouseout="hideTooltips"
  >
    {{ $options.i18n.button }}
  </gl-button>
</template>
