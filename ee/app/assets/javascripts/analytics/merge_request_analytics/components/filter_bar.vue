<script>
import { mapActions, mapState } from 'vuex';
import {
  OPERATORS_IS,
  OPTIONS_NONE_ANY,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_SOURCE_BRANCH,
  TOKEN_TITLE_TARGET_BRANCH,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_SOURCE_BRANCH,
  TOKEN_TYPE_TARGET_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  prepareTokens,
  processFilters,
  filterToQueryObject,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import BranchToken from '~/vue_shared/components/filtered_search_bar/tokens/branch_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import MilestoneToken from '~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

export default {
  name: 'FilterBar',
  components: {
    FilteredSearchBar,
    UrlSync,
  },
  inject: ['fullPath', 'type'],
  computed: {
    ...mapState('filters', {
      selectedSourceBranch: (state) => state.branches.source.selected,
      selectedTargetBranch: (state) => state.branches.target.selected,
      selectedMilestone: (state) => state.milestones.selected,
      selectedAuthor: (state) => state.authors.selected,
      selectedAssignee: (state) => state.assignees.selected,
      selectedLabelList: (state) => state.labels.selectedList,
      milestonesData: (state) => state.milestones.data,
      labelsData: (state) => state.labels.data,
      assigneesData: (state) => state.assignees.data,
      authorsData: (state) => state.authors.data,
      branchesData: (state) => state.branches.data,
    }),
    tokens() {
      return [
        {
          icon: 'branch',
          title: TOKEN_TITLE_SOURCE_BRANCH,
          type: TOKEN_TYPE_SOURCE_BRANCH,
          token: BranchToken,
          initialBranches: this.branchesData,
          unique: true,
          operators: OPERATORS_IS,
          fetchBranches: this.fetchBranches,
        },
        {
          icon: 'branch',
          title: TOKEN_TITLE_TARGET_BRANCH,
          type: TOKEN_TYPE_TARGET_BRANCH,
          token: BranchToken,
          initialBranches: this.branchesData,
          unique: true,
          operators: OPERATORS_IS,
          fetchBranches: this.fetchBranches,
        },
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
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          token: UserToken,
          initialUsers: this.authorsData,
          unique: true,
          operators: OPERATORS_IS,
          fetchUsers: this.fetchAuthors,
        },
        {
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          type: TOKEN_TYPE_ASSIGNEE,
          token: UserToken,
          initialUsers: this.assigneesData,
          unique: false,
          operators: OPERATORS_IS,
          fetchUsers: this.fetchAssignees,
        },
      ];
    },
    query() {
      return filterToQueryObject({
        source_branch_name: this.selectedSourceBranch,
        target_branch_name: this.selectedTargetBranch,
        milestone_title: this.selectedMilestone,
        label_name: this.selectedLabelList,
        author_username: this.selectedAuthor,
        assignee_username: this.selectedAssignee,
      });
    },
    initialFilterValue() {
      return prepareTokens({
        [TOKEN_TYPE_SOURCE_BRANCH]: this.selectedSourceBranch,
        [TOKEN_TYPE_TARGET_BRANCH]: this.selectedTargetBranch,
        [TOKEN_TYPE_MILESTONE]: this.selectedMilestone,
        [TOKEN_TYPE_AUTHOR]: this.selectedAuthor,
        [TOKEN_TYPE_ASSIGNEE]: this.selectedAssignee,
        [TOKEN_TYPE_LABEL]: this.selectedLabelList,
      });
    },
  },
  methods: {
    ...mapActions('filters', [
      'setFilters',
      'fetchBranches',
      'fetchMilestones',
      'fetchAuthors',
      'fetchAssignees',
      'fetchLabels',
    ]),
    handleFilter(filters) {
      const {
        [TOKEN_TYPE_SOURCE_BRANCH]: sourceBranch,
        [TOKEN_TYPE_TARGET_BRANCH]: targetBranch,
        [TOKEN_TYPE_MILESTONE]: milestone,
        [TOKEN_TYPE_AUTHOR]: author,
        [TOKEN_TYPE_ASSIGNEE]: assignee,
        [TOKEN_TYPE_LABEL]: labels,
      } = processFilters(filters);

      this.setFilters({
        selectedSourceBranch: sourceBranch ? sourceBranch[0] : null,
        selectedTargetBranch: targetBranch ? targetBranch[0] : null,
        selectedAuthor: author ? author[0] : null,
        selectedMilestone: milestone ? milestone[0] : null,
        selectedAssignee: assignee ? assignee[0] : null,
        selectedLabelList: labels || [],
      });
    },
  },
};
</script>

<template>
  <div>
    <filtered-search-bar
      class="gl-flex-grow-1"
      :namespace="fullPath"
      recent-searches-storage-key="merge-request-analytics"
      :search-input-placeholder="__('Filter results')"
      :tokens="tokens"
      :initial-filter-value="initialFilterValue"
      suggestions-list-class="gl-z-index-9999"
      @onFilter="handleFilter"
    />
    <url-sync :query="query" />
  </div>
</template>
