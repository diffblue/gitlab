<script>
import { ITEM_TYPE } from '~/groups/constants';
import IssuesListApp from '~/issues/list/components/issues_list_app.vue';
import { TOKEN_TYPE_EPIC, TOKEN_TYPE_ITERATION, TOKEN_TYPE_WEIGHT } from '~/issues/list/constants';
import {
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_WEIGHT,
} from 'ee/vue_shared/components/filtered_search_bar/constants';
import BlockingIssuesCount from 'ee/issues/components/blocking_issues_count.vue';
import searchIterationsQuery from '../queries/search_iterations.query.graphql';

const EpicToken = () =>
  import('ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue');
const IterationToken = () =>
  import('ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue');
const WeightToken = () =>
  import('ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue');

export default {
  components: {
    BlockingIssuesCount,
    IssuesListApp,
  },
  inject: ['fullPath', 'groupPath', 'hasIssueWeightsFeature', 'hasIterationsFeature', 'isProject'],
  computed: {
    namespace() {
      return this.isProject ? ITEM_TYPE.PROJECT : ITEM_TYPE.GROUP;
    },
    searchTokens() {
      const tokens = [];

      if (this.hasIterationsFeature) {
        tokens.push({
          type: TOKEN_TYPE_ITERATION,
          title: TOKEN_TITLE_ITERATION,
          icon: 'iteration',
          token: IterationToken,
          fetchIterations: this.fetchIterations,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-iteration`,
        });
      }

      if (this.groupPath) {
        tokens.push({
          type: TOKEN_TYPE_EPIC,
          title: TOKEN_TITLE_EPIC,
          icon: 'epic',
          token: EpicToken,
          unique: true,
          symbol: '&',
          idProperty: 'id',
          useIdValue: true,
          recentSuggestionsStorageKey: `${this.fullPath}-issues-recent-tokens-epic`,
          fullPath: this.groupPath,
        });
      }

      if (this.hasIssueWeightsFeature) {
        tokens.push({
          type: TOKEN_TYPE_WEIGHT,
          title: TOKEN_TITLE_WEIGHT,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        });
      }

      return tokens;
    },
  },
  methods: {
    fetchIterations(search) {
      const id = Number(search);
      const variables =
        !search || Number.isNaN(id)
          ? { fullPath: this.fullPath, search, isProject: this.isProject }
          : { fullPath: this.fullPath, id, isProject: this.isProject };

      return this.$apollo
        .query({
          query: searchIterationsQuery,
          variables,
        })
        .then(({ data }) => data[this.namespace]?.iterations.nodes);
    },
  },
};
</script>

<template>
  <issues-list-app #default="{ issuable }" :ee-search-tokens="searchTokens">
    <blocking-issues-count
      class="blocking-issues gl-display-none gl-sm-display-block"
      :blocking-issues-count="issuable.blockingCount"
      is-list-item
      data-testid="blocking-issues"
    />
  </issues-list-app>
</template>
