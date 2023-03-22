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
  computed: {
    rules() {
      return this.environment[this.ruleKey] || [];
    },
  },
  methods: {
    addRule(environment) {
      this.$emit('addRule', { environment, ruleKey: this.ruleKey });
    },
  },
};
</script>
<template>
  <div>
    <template v-if="rules.length">
      <div class="gl-p-5 gl-bg-gray-50 gl-w-full gl-display-flex gl-font-weight-bold">
        <slot name="card-header"></slot>
      </div>
      <div
        v-for="rule in rules"
        :key="rule.id"
        :data-testid="`${ruleKey}-${rule.id}`"
        class="gl-border-t gl-p-5 gl-display-flex gl-align-items-center gl-w-full"
      >
        <slot name="rule" :rule="rule" :rule-key="ruleKey"></slot>
      </div>
    </template>
    <div
      class="gl-p-5 gl-display-flex gl-align-items-center"
      :class="{ 'gl-border-t': rules.length }"
    >
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
</template>
