<script>
import CiResourcesListItem from './ci_resources_list_item.vue';

export default {
  components: {
    CiResourcesListItem,
  },
  props: {
    components: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <ul>
    <ci-resources-list-item
      v-for="component in components"
      :key="component.id"
      :component="component"
    />
  </ul>
</template>
