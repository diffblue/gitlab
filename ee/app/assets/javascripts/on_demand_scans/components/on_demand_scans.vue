<script>
import { GlTabs } from '@gitlab/ui';
import AllTab from './tabs/all.vue';
import RunningTab from './tabs/running.vue';
import FinishedTab from './tabs/finished.vue';
import ScheduledTab from './tabs/scheduled.vue';
import EmptyState from './empty_state.vue';

const TABS = {
  all: {
    component: AllTab,
  },
  running: {
    component: RunningTab,
  },
  finished: {
    component: FinishedTab,
  },
  scheduled: {
    component: ScheduledTab,
  },
};

export default {
  TABS,
  components: {
    GlTabs,
    AllTab,
    RunningTab,
    FinishedTab,
    ScheduledTab,
    EmptyState,
  },
  data() {
    return {
      activeTabIndex: 0,
      hasData: false,
    };
  },
  computed: {
    activeTab: {
      set(newTabIndex) {
        const newTabId = Object.keys(TABS)[newTabIndex];
        if (this.$route.params.tabId !== newTabId) {
          this.$router.push(`/${newTabId}`);
        }
        this.activeTabIndex = newTabIndex;
      },
      get() {
        return this.activeTabIndex;
      },
    },
  },
  created() {
    const tabIndex = Object.keys(TABS).findIndex((tab) => tab === this.$route.params.tabId);
    if (tabIndex !== -1) {
      this.activeTabIndex = tabIndex;
    }
  },
};
</script>

<template>
  <gl-tabs v-if="hasData" v-model="activeTab">
    <component :is="tab.component" v-for="(tab, key) in $options.TABS" :key="key" :item-count="0" />
  </gl-tabs>
  <empty-state v-else />
</template>
