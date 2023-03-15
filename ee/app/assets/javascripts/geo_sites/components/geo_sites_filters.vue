<script>
import { GlTabs, GlTab, GlBadge, GlSearchBoxByType } from '@gitlab/ui';
import { mapGetters, mapActions, mapState } from 'vuex';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { HEALTH_STATUS_UI, STATUS_FILTER_QUERY_PARAM } from 'ee/geo_sites/constants';

export default {
  name: 'GeoSitesFilters',
  i18n: {
    allTab: s__('Geo|All'),
    searchPlaceholder: s__('Geo|Filter Geo sites'),
  },
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    GlSearchBoxByType,
  },
  props: {
    totalSites: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    ...mapGetters(['countSitesForStatus']),
    ...mapState(['searchFilter']),
    search: {
      get() {
        return this.searchFilter;
      },
      set(search) {
        this.setSearchFilter(search);
      },
    },
    tabs() {
      const ALL_TAB = { text: this.$options.i18n.allTab, count: this.totalSites, status: null };
      const tabs = [ALL_TAB];

      Object.entries(HEALTH_STATUS_UI).forEach(([status, tab]) => {
        const count = this.countSitesForStatus(status);

        if (count) {
          tabs.push({ ...tab, count, status });
        }
      });

      return tabs;
    },
  },
  watch: {
    searchFilter(search) {
      updateHistory({ url: setUrlParams({ search: search || null }), replace: true });
    },
  },
  methods: {
    ...mapActions(['setStatusFilter', 'setSearchFilter']),
    tabChange(tabIndex) {
      this.setStatusFilter(this.tabs[tabIndex]?.status);
    },
  },
  STATUS_FILTER_QUERY_PARAM,
};
</script>

<template>
  <gl-tabs
    class="gl-display-grid geo-site-filter-grid-columns"
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
    <div class="gl-pb-3 gl-border-b-1 gl-border-b-solid gl-border-gray-100">
      <gl-search-box-by-type v-model="search" :placeholder="$options.i18n.searchPlaceholder" />
    </div>
  </gl-tabs>
</template>
