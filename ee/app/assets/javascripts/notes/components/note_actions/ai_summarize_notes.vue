<script>
import { GlButton, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import { MAX_REQUEST_TIMEOUT } from 'ee/notes/constants';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  components: {
    GlButton,
    GlBadge,
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
      this.$root.$emit(BV_HIDE_TOOLTIP);

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

          if (errors[0]) {
            this.handleError(new Error(errors[0]));
          }

          clearTimeout(this.timeout);
        })
        .catch(this.handleError);
    },
    handleError(error) {
      const alertOptions = error ? { captureError: true, error } : {};
      this.errorAlert = createAlert({
        message: error ? error.message : __('Something went wrong'),
        ...alertOptions,
      });
      this.$parent.$emit('set-ai-loading', false);
    },
  },
  i18n: {
    button: s__('AISummary|See summary'),
    badge: s__('AISummary|Experiment'),
    tooltip: s__('AISummary|Generates a summary of all public comments'),
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.focus.hover
    :disabled="loading"
    :loading="loading"
    :title="$options.i18n.tooltip"
    :aria-label="$options.i18n.tooltip"
    @click="onClick"
  >
    {{ $options.i18n.button }}
    <gl-badge variant="info" size="sm">{{ $options.i18n.badge }}</gl-badge>
  </gl-button>
</template>
