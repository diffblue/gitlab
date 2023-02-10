<script>
import { GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';

export default {
  components: {
    GlButton,
  },
  props: {
    ruleKey: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    addButtonText: {
      type: String,
      required: true,
    },
    environment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { isAddingRule: false, modalId: uniqueId('add-protected-environment-modal') };
  },
  methods: {
    addRule(env) {
      this.$emit('addRule', env);
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-rounded gl-border">
      <div class="gl-p-5 gl-bg-gray-50 gl-w-full gl-display-flex">
        <slot name="card-header"></slot>
      </div>
      <div
        v-for="rule in environment[ruleKey]"
        :key="rule.id"
        class="gl-border-t gl-p-5 gl-display-flex gl-align-items-center gl-w-full"
      >
        <slot name="rule" :rule="rule"></slot>
      </div>
      <div class="gl-border-t gl-p-5 gl-display-flex gl-align-items-center">
        <gl-button
          category="secondary"
          variant="confirm"
          class="gl-ml-auto"
          :loading="loading"
          @click="addRule(environment)"
        >
          {{ addButtonText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
