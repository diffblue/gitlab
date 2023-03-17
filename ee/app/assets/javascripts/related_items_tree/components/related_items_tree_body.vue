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
  <div class="related-items-tree-body sortable-container gl-bg-gray-10">
    <tree-root :parent-item="parentItem" :children="children" />
  </div>
</template>
