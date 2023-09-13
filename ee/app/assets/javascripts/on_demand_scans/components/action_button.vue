<script>
import { GlButton, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash';

export default {
  components: {
    GlButton,
    GlTooltip,
  },
  props: {
    actionType: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      buttonId: uniqueId(this.actionType),
    };
  },
  methods: {
    onClick() {
      this.$root.$emit('bv::hide::tooltip', this.buttonId);
      this.$emit('click');
    },
  },
};
</script>

<template>
  <span>
    <gl-button
      v-bind="$attrs"
      :id="buttonId"
      :aria-label="label"
      :loading="isLoading"
      :icon="actionType"
      size="small"
      @click="onClick"
    />
    <gl-tooltip ref="tooltip" :target="buttonId" placement="top" triggers="hover">
      {{ label }}
    </gl-tooltip>
  </span>
</template>
