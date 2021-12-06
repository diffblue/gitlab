<script>
import BridgeEmptyState from './components/empty_state.vue';
import BridgeSidebar from './components/sidebar.vue';

export default {
  name: 'BridgePageApp',
  components: {
    BridgeEmptyState,
    BridgeSidebar,
  },
  inject: {
    buildName: {
      type: Object,
      required: false,
      default: {},
    },
  },
};
</script>
<template>
  <div>
    <!-- TODO: get job details and show CI header -->
    <bridge-empty-state />
    <bridge-sidebar />
  </div>
</template>
