<script>
import { GlCard, GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'DastProfileSummaryCard',
  components: {
    GlCard,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  props: {
    allowSelection: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEditable: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  i18n: {
    editTitle: __('Edit Profile'),
    selectTitle: __('Select Profile'),
    selectBtnText: __('Select'),
  },
};
</script>

<template>
  <gl-card class="gl-m-3 gl-p-0!">
    <template #header>
      <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center">
        <h3 class="gl-font-lg gl-my-0">
          <slot name="title"></slot>
        </h3>
        <div v-if="allowSelection || isEditable" class="gl-display-flex gl-gap-x-3">
          <gl-button
            v-if="allowSelection"
            v-gl-tooltip
            data-testid="selected-profile-edit-link"
            category="primary"
            :title="$options.i18n.selectTitle"
            >{{ $options.i18n.selectBtnText }}</gl-button
          >
          <gl-button
            v-if="isEditable"
            v-gl-tooltip
            data-testid="selected-profile-edit-link"
            category="primary"
            icon="pencil"
            :title="$options.i18n.editTitle"
            :aria-label="$options.i18n.editTitle"
          />
        </div>
      </div>
    </template>
    <slot name="summary"></slot>
  </gl-card>
</template>
