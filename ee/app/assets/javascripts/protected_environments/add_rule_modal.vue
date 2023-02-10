<script>
import { GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    modalProps() {
      return {
        ...this.$attrs,
        modalId: uniqueId('add-protected-environment-modal'),
        actionPrimary: { text: __('Save') },
        actionSecondary: { text: __('Cancel') },
      };
    },
  },
};
</script>
<template>
  <gl-modal
    v-bind="modalProps"
    :visible="visible"
    static
    @primary="$emit('saveRule')"
    @change="$emit('change', $event)"
  >
    <slot name="add-rule-form"></slot>
  </gl-modal>
</template>
