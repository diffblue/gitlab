<script>
export default {
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    children: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="gl-new-card-body gl-py-0 gl-mx-n1 gl-mb-n2">
    <tree-root :parent-item="parentItem" :children="children" />
  </div>
</template>
