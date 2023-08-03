<!-- eslint-disable vue/multi-word-component-names -->
<script>
export default {
  props: {
    criteria: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <ul v-if="criteria.variables.length" class="gl-list-style-none gl-pl-0 gl-mt-2">
    <li v-for="{ variable, value } in criteria.variables" :key="variable">
      {{ variable }}: {{ value }}
    </li>
  </ul>
</template>
