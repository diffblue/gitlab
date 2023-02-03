<script>
export default {
  props: {
    ruleKey: {
      type: String,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
    environment: {
      type: Object,
      required: true,
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
    </div>
  </div>
</template>
