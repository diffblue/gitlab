<script>
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { s__ } from '~/locale';
import { HEALTH_STATUS_UI, STATUS_FILTER_QUERY_PARAM } from 'ee/geo_nodes/constants';

export default {
  name: 'GeoNodesFilters',
  i18n: {
    allTab: s__('Geo|All'),
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
  },
  props: {
    totalNodes: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    ...mapGetters(['countNodesForStatus']),
    tabs() {
      const ALL_TAB = { text: this.$options.i18n.allTab, count: this.totalNodes, status: null };
      const tabs = [ALL_TAB];

      Object.entries(HEALTH_STATUS_UI).forEach(([status, tab]) => {
        const count = this.countNodesForStatus(status);

        if (count) {
          tabs.push({ ...tab, count, status });
        }
      });

      return tabs;
    },
  },
  methods: {
    ...mapActions(['setStatusFilter']),
    tabChange(tabIndex) {
      this.setStatusFilter(this.tabs[tabIndex]?.status);
    },
  },
  STATUS_FILTER_QUERY_PARAM,
};
</script>

<template>
  <gl-tabs
    sync-active-tab-with-query-params
    :query-param-name="$options.STATUS_FILTER_QUERY_PARAM"
    data-testid="geo-sites-filter"
    @input="tabChange"
  >
    <gl-tab v-for="tab in tabs" :key="tab.text" :query-param-value="tab.status">
      <template #title>
        <span>{{ tab.text }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
