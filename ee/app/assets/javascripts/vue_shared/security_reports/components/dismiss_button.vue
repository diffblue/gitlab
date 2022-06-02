<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'DismissButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isDismissing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDismissed: {
      type: Boolean,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    buttonText() {
      return this.isDismissed
        ? s__('vulnerability|Undo dismiss')
        : s__('vulnerability|Dismiss vulnerability');
    },
  },
  methods: {
    handleDismissClick() {
      if (this.isDismissed) {
        this.$emit('revertDismissVulnerability');
      } else {
        this.$emit('dismissVulnerability');
      }
    },
  },
};
</script>

<template>
  <div class="btn-group" role="group">
    <gl-button
      :loading="isDismissing"
      :disabled="isDismissing || disabled"
      class="js-dismiss-btn"
      @click="handleDismissClick"
    >
      {{ buttonText }}
    </gl-button>
    <gl-button
      v-if="!isDismissed"
      v-gl-tooltip
      :disabled="disabled"
      :title="s__('vulnerability|Add comment and dismiss')"
      data-qa-selector="dismiss_with_comment_button"
      class="js-dismiss-with-comment"
      :aria-label="s__('vulnerability|Add comment and dismiss')"
      icon="comment"
      @click="$emit('openDismissalCommentBox')"
    />
  </div>
</template>
