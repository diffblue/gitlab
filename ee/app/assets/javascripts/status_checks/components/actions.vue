<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    statusCheck: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    editButton: __('Edit'),
    removeButton: __('Remove'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-end gl-mt-n2 gl-mb-n2">
    <gl-button
      size="small"
      icon="pencil"
      :title="$options.i18n.editButton"
      :aria-label="$options.i18n.editButton"
      data-testid="edit-btn"
      @click="$emit('open-update-modal', statusCheck)"
    />
    <gl-button
      size="small"
      category="secondary"
      variant="danger"
      icon="remove"
      class="gl-ml-3"
      :title="$options.i18n.removeButton"
      :aria-label="$options.i18n.removeButton"
      data-testid="remove-btn"
      @click="$emit('open-delete-modal', statusCheck)"
    />
  </div>
</template>
