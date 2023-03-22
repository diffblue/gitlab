<script>
export default {
  props: {
    component: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <li>
    {{ component.id }}
  </li>
</template>
