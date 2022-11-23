<script>
import { mapState, mapActions } from 'vuex';
import {
  OPTIONS_NONE_ANY,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  prepareTokens,
  processFilters,
  filterToQueryObject,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  components: {
    FilteredSearchBar,
    UrlSync,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('filters', {
      selectedMilestone: (state) => state.milestones.selected,
      selectedLabelList: (state) => state.labels.selectedList,
      milestonesData: (state) => state.milestones.data,
      labelsData: (state) => state.labels.data,
    }),
    tokens() {
      return [
        {
          icon: 'clock',
          title: TOKEN_TITLE_MILESTONE,
          type: TOKEN_TYPE_MILESTONE,
          token: MilestoneToken,
          initialMilestones: this.milestonesData,
          unique: true,
          symbol: '%',
          fetchMilestones: this.fetchMilestones,
        },
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          token: LabelToken,
          defaultLabels: OPTIONS_NONE_ANY,
          initialLabels: this.labelsData,
          unique: false,
          symbol: '~',
          fetchLabels: this.fetchLabels,
        },
      ];
    },
    query() {
      return filterToQueryObject({
        milestone_title: this.selectedMilestone,
        label_name: this.selectedLabelList,
      });
    },
    initialFilterValue() {
      return prepareTokens({
        [TOKEN_TYPE_MILESTONE]: this.selectedMilestone,
        [TOKEN_TYPE_LABEL]: this.selectedLabelList,
      });
    },
  },
  methods: {
    ...mapActions('filters', ['setFilters', 'fetchMilestones', 'fetchLabels']),
    handleFilter(filters) {
      const { [TOKEN_TYPE_LABEL]: labels, [TOKEN_TYPE_MILESTONE]: milestone } = processFilters(
        filters,
      );

      this.setFilters({
        selectedMilestone: milestone ? milestone[0] : null,
        selectedLabelList: labels || [],
      });
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-bar
      class="gl-flex-grow-1 row-content-block"
      :namespace="projectPath"
      recent-searches-storage-key="code-review-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue"
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
