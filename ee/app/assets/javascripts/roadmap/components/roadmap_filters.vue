<script>
import { GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

import EpicsFilteredSearchMixin from '../mixins/filtered_search_mixin';

export default {
  availableSortOptions: [
    {
      id: 1,
      title: __('Start date'),
      sortDirection: {
        descending: 'start_date_desc',
        ascending: 'start_date_asc',
      },
    },
    {
      id: 2,
      title: __('Due date'),
      sortDirection: {
        descending: 'end_date_desc',
        ascending: 'end_date_asc',
      },
    },
  ],
  components: {
    GlButton,
    FilteredSearchBar,
  },
  mixins: [EpicsFilteredSearchMixin],
  computed: {
    ...mapState([
      'presetType',
      'epicsState',
      'sortedBy',
      'filterParams',
      'timeframeRangeType',
      'isProgressTrackingActive',
      'progressTracking',
      'isShowingMilestones',
      'milestonesType',
      'isShowingLabels',
    ]),
  },
  watch: {
    urlParams: {
      deep: true,
      immediate: true,
      handler(params) {
        if (Object.keys(params).length) {
          updateHistory({
            url: setUrlParams(params, window.location.href, true, false, true),
            title: document.title,
            replace: true,
          });
        }
      },
    },
  },
  methods: {
    ...mapActions(['setFilterParams', 'setSortedBy', 'fetchEpics']),
    handleFilterEpics(filters, cleared) {
      if (filters.length || cleared) {
        this.setFilterParams(this.getFilterParams(filters));
        this.fetchEpics();
      }
    },
    handleSortEpics(sortedBy) {
      this.setSortedBy(sortedBy);
      this.fetchEpics();
    },
  },
  i18n: {
    settings: __('Settings'),
  },
};
</script>

<template>
  <div class="epics-filters epics-roadmap-filters epics-roadmap-filters-gl-ui">
    <div
      class="epics-details-filters filtered-search-block gl-display-flex gl-flex-direction-column gl-xl-flex-direction-row gl-p-3 row-content-block second-block"
    >
      <filtered-search-bar
        :namespace="groupFullPath"
        :search-input-placeholder="__('Search or filter results...')"
        :tokens="getFilteredSearchTokens()"
        :sort-options="$options.availableSortOptions"
        :initial-filter-value="getFilteredSearchValue()"
        :initial-sort-by="sortedBy"
        sync-filter-and-sort
        terms-as-tokens
        recent-searches-storage-key="epics"
        class="gl-flex-grow-1"
        @onFilter="handleFilterEpics"
        @onSort="handleSortEpics"
      />
      <gl-button
        icon="settings"
        class="gl-xl-ml-3 gl-inset-border-1-gray-400!"
        :aria-label="$options.i18n.settings"
        data-testid="settings-button"
        @click="$emit('toggleSettings', $event)"
      >
        {{ $options.i18n.settings }}
      </gl-button>
    </div>
  </div>
</template>
