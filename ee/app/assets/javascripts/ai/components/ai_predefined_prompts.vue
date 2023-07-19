<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'AiPredefinedPrompts',
  components: {
    GlButton,
  },
  props: {
    prompts: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  methods: {
    hasPrompts() {
      return this.prompts.length > 0;
    },
  },
};
</script>
<template>
  <div v-if="hasPrompts()" class="gl-text-right">
    <div v-for="(prompt, index) in prompts" :key="`question-${index}`" class="gl-mt-3">
      <gl-button
        :aria-label="prompt"
        category="secondary"
        variant="confirm"
        class="gl-text-left"
        @click="$emit('click', prompt)"
        ><span class="gl-white-space-normal">{{ prompt }}</span></gl-button
      >
    </div>
  </div>
</template>
