<script>
import GroupsListItem from './groups_list_item.vue';

export default {
  components: { GroupsListItem },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    showGroupIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-list-style-none">
    <groups-list-item
      v-for="group in groups"
      :key="group.id"
      :group="group"
      :show-group-icon="showGroupIcon"
      @delete="$emit('delete', $event)"
    />
  </ul>
</template>
