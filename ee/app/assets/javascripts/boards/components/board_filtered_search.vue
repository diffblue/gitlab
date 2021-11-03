<script>
import { mapState, mapActions } from 'vuex';
import { isEmpty } from 'lodash';
import BoardFilteredSearchCe from '~/boards/components/board_filtered_search.vue';
import { transformBoardConfig } from 'ee/boards/boards_util';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { updateHistory, queryToObject } from '~/lib/utils/url_utility';

export default {
  components: { BoardFilteredSearchCe },
  props: {
    tokens: {
      required: true,
      type: Array,
    },
  },
  data() {
    return {
      filterParams: {},
      resetFilters: false,
    };
  },
  computed: {
    ...mapState({ boardScopeConfig: ({ boardConfig }) => boardConfig }),
    shouldRenderComponent() {
      return this.resetFilters || !isEmpty(this.boardScopeConfig);
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

          this.resetFilters = true;
        }
      }
    },
  },
  methods: {
    ...mapActions(['performSearch']),
  },
};
</script>

<template>
  <board-filtered-search-ce
    v-if="shouldRenderComponent"
    :ee-filters="filterParams"
    v-bind="{ ...$props, ...$attrs }"
  />
</template>
