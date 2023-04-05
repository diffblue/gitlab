<script>
import CiResourcesListItem from './ci_resources_list_item.vue';

export default {
  components: {
    CiResourcesListItem,
  },
  props: {
    resources: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <ul class="gl-p-0">
    <ci-resources-list-item v-for="resource in resources" :key="resource.id" :resource="resource" />
  </ul>
</template>
