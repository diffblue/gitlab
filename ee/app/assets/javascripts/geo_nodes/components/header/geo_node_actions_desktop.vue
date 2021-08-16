<script>
import { GlButton } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { __ } from '~/locale';

export default {
  name: 'GeoNodeActionsDesktop',
  i18n: {
    editButtonLabel: __('Edit'),
    removeButtonLabel: __('Remove'),
  },
  components: {
    GlButton,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['canRemoveNode']),
  },
};
</script>

<template>
  <div>
    <gl-button class="gl-mr-3" :href="node.webEditUrl">{{
      $options.i18n.editButtonLabel
    }}</gl-button>
    <gl-button
      variant="danger"
      category="secondary"
      :disabled="!canRemoveNode(node.id)"
      data-testid="geo-desktop-remove-action"
      @click="$emit('remove')"
      >{{ $options.i18n.removeButtonLabel }}</gl-button
    >
  </div>
</template>
