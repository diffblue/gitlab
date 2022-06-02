<script>
export default {
  name: 'PolicyEnvironments',
  props: {
    environments: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    nodes() {
      return this.environments?.nodes ?? [];
    },
  },
};
</script>

<template>
  <span>
    <template v-if="nodes.length > 0">
      {{ nodes[0].name }}
      <span v-if="nodes.length > 1" class="gl-text-gray-600">
        {{ sprintf(s__('SecurityPolicies|+%{count} more'), { count: nodes.length - 1 }) }}
      </span>
    </template>

    <template v-else>-</template>
  </span>
</template>
