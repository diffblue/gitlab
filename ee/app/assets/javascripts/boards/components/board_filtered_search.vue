<script>
import { mapState, mapActions } from 'vuex';
import { isEmpty } from 'lodash';
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';
import { transformBoardConfig } from 'ee/boards/boards_util';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { updateHistory, queryToObject, getParameterByName } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  components: { BoardFilteredSearchCe },
  inject: ['boardBaseUrl', 'isApolloBoard'],
  props: {
    tokens: {
      required: true,
      type: Array,
    },
    board: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      filterParams: {},
    };
  },
  computed: {
    ...mapState({ boardScopeConfig: ({ boardConfig }) => boardConfig }),
    boardScope() {
      if (!this.isApolloBoard) return {};
      const { board } = this;
      return {
        milestoneId: board.milestone?.id || null,
        milestoneTitle: board.milestone?.title || null,
        iterationId: board.iteration?.id || null,
        iterationTitle: board.iteration?.title || null,
        iterationCadenceId: board.iterationCadence?.id || null,
        assigneeId: board.assignee?.id || null,
        assigneeUsername: board.assignee?.username || null,
        labels: board.labels || [],
        labelIds: board.labels?.map((label) => label.id) || [],
        weight: board.weight,
      };
    },
  },
  watch: {
    boardScopeConfig(newVal) {
      if (!isEmpty(newVal)) {
        const boardConfigPath = transformBoardConfig(newVal);
        if (boardConfigPath !== '') {
          const filterPath = window.location.search ? `${window.location.search}&` : '?';
          updateHistory({
            url: `${filterPath}${transformBoardConfig(newVal)}`,
          });

          this.performSearch();

          const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });

          this.filterParams = {
            ...convertObjectPropsToCamelCase(rawFilterParams, {}),
          };
        }
      }
    },
    board: {
      deep: true,
      handler(_, oldVal) {
        // Ensure we're maintaining Swimlanes view
        const param = getParameterByName('group_by')
          ? `?group_by=${getParameterByName('group_by')}`
          : '';
        if (oldVal.id) {
          updateHistory({
            url: `${this.boardBaseUrl}/${getIdFromGraphQLId(this.board.id)}${param}`,
          });
        }
        // Update URL, filter params and tokens when the board gets updated
        if (!isEmpty(this.boardScope)) {
          const boardConfigPath = transformBoardConfig(this.boardScope);
          if (boardConfigPath !== '') {
            const filterPath = window.location.search ? `${window.location.search}&` : '?';
            updateHistory({
              url: `${filterPath}${boardConfigPath}`,
            });

            const rawFilterParams = queryToObject(window.location.search, { gatherArrays: true });

            this.filterParams = {
              ...convertObjectPropsToCamelCase(rawFilterParams, {}),
            };
          } else {
            updateHistory({
              url: `${this.boardBaseUrl}/${getIdFromGraphQLId(this.board.id)}${param}`,
            });
          }
        }
        this.$refs.filteredSearch.updateTokens();
      },
    },
  },
  methods: {
    ...mapActions(['performSearch']),
  },
};
</script>

<template>
  <board-filtered-search-ce
    ref="filteredSearch"
    :ee-filters="filterParams"
    v-bind="{ ...$props, ...$attrs }"
    @setFilters="$emit('setFilters', $event)"
  />
</template>
