<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { DELETE_BUTTON_LABEL, EDIT_BUTTON_LABEL } from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
  },
  props: {
    framework: {
      type: Object,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    editFramework: EDIT_BUTTON_LABEL,
    deleteFramework: DELETE_BUTTON_LABEL,
  },
};
</script>
<template>
  <div>
    <div v-if="framework.editPath" class="gl-display-flex">
      <gl-button
        v-gl-tooltip="$options.i18n.editFramework"
        :disabled="loading"
        :aria-label="$options.i18n.editFramework"
        :href="framework.editPath"
        data-testid="compliance-framework-edit-button"
        icon="pencil"
        category="tertiary"
      />
      <gl-button
        v-gl-tooltip="$options.i18n.deleteFramework"
        class="gl-ml-3"
        :loading="loading"
        :disabled="loading"
        :aria-label="$options.i18n.deleteFramework"
        data-testid="compliance-framework-delete-button"
        icon="remove"
        category="tertiary"
        @click="$emit('delete', framework)"
      />
    </div>
  </div>
</template>
