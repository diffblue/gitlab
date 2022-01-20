<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  name: 'GeoNodeActionsDesktop',
  i18n: {
    editButtonTooltip: s__('Geo|Edit %{nodeType} site'),
    removeButtonTooltip: s__('Geo|Remove %{nodeType} site'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['canRemoveNode']),
    nodeType() {
      return this.node.primary ? s__('Geo|primary') : s__('Geo|secondary');
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      v-gl-tooltip
      :title="sprintf($options.i18n.editButtonTooltip, { nodeType })"
      :aria-label="sprintf($options.i18n.editButtonTooltip, { nodeType })"
      icon="pencil"
      class="gl-mr-3"
      data-testid="geo-desktop-edit-action"
      :href="node.webEditUrl"
    />
    <gl-button
      v-gl-tooltip
      :title="sprintf($options.i18n.removeButtonTooltip, { nodeType })"
      :aria-label="sprintf($options.i18n.removeButtonTooltip, { nodeType })"
      icon="remove"
      :disabled="!canRemoveNode(node.id)"
      data-testid="geo-desktop-remove-action"
      @click="$emit('remove')"
    />
  </div>
</template>
