<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'GenericBaseLayoutComponent',
  components: {
    GlButton,
  },
  props: {
    contentClasses: {
      type: String,
      required: false,
      default: '',
    },
    ruleLabel: {
      type: String,
      required: false,
      default: '',
    },
    showRemoveButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    contentClass() {
      return `gl-flex-grow-1 gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap ${this.contentClasses}`;
    },
    showLabel() {
      return Boolean(this.ruleLabel);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-gap-3 security-policies-bg-gray-10 gl-rounded-base gl-p-5">
    <div v-if="showLabel" class="gl-min-w-7">
      <label
        data-testid="base-label"
        for="content"
        class="gl-text-transform-uppercase gl-font-lg gl-w-6 gl-pl-2"
      >
        {{ ruleLabel }}
      </label>
    </div>

    <div data-testid="content" :class="contentClass">
      <slot name="selector"> </slot>
      <slot name="content"></slot>
    </div>

    <div v-if="showRemoveButton" class="gl-min-w-7">
      <gl-button
        icon="remove"
        category="tertiary"
        :aria-label="__('Remove')"
        data-testid="remove-rule"
        @click="$emit('remove')"
      />
    </div>
  </div>
</template>
