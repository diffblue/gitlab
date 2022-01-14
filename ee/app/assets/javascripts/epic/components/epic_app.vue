<script>
import SidebarContext from '../sidebar_context';

import EpicBody from './epic_body.vue';
import EpicHeader from './epic_header.vue';
import EpicTabs from './epic_tabs.vue';

export default {
  components: {
    EpicHeader,
    EpicBody,
    EpicTabs,
  },
  mounted() {
    this.sidebarContext = new SidebarContext();
  },
};
</script>

<template>
  <div class="epic-page-container">
    <epic-header />
    <epic-body />
    <epic-tabs />
  </div>
</template>
