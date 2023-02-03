<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { mapActions } from 'vuex';
import BoardListHeaderFoss from '~/boards/components/board_list_header.vue';
import { n__, __, sprintf } from '~/locale';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import epicListQuery from 'ee/boards/graphql/epic_board_lists_deferred.query.graphql';

export default {
  extends: BoardListHeaderFoss,
  inject: ['weightFeatureAvailable', 'isEpicBoard'],
  apollo: {
    boardList: {
      query: listQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      skip() {
        return this.isEpicBoard;
      },
      context: {
        isSingleRequest: true,
      },
    },
    epicBoardList: {
      query: epicListQuery,
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      skip() {
        return !this.isEpicBoard || !this.glFeatures.feEpicBoardTotalWeight;
      },
    },
  },
  computed: {
    countIcon() {
      return this.isEpicBoard ? 'epic' : 'issues';
    },
    itemsCount() {
      return this.isEpicBoard ? this.list.epicsCount : this.boardList?.issuesCount;
    },
    itemsTooltipLabel() {
      const { maxIssueCount } = this.list;
      if (maxIssueCount > 0) {
        return sprintf(__('%{itemsCount} issues with a limit of %{maxIssueCount}'), {
          itemsCount: this.itemsCount,
          maxIssueCount,
        });
      }

      return this.isEpicBoard
        ? n__(`%d epic`, `%d epics`, this.itemsCount)
        : n__(`%d issue`, `%d issues`, this.itemsCount);
    },
    weightCountToolTip() {
      if (!this.weightFeatureAvailable) {
        return null;
      }

      return sprintf(__('%{totalWeight} total weight'), { totalWeight: this.totalWeight });
    },
    isEpicBoardListLoading() {
      return this.$apollo.queries.epicBoardList.loading;
    },
    totalWeight() {
      if (this.isEpicBoard && this.glFeatures.feEpicBoardTotalWeight) {
        return this.epicBoardList?.metadata?.totalWeight || 0;
      }

      return this.boardList?.totalWeight;
    },
    canShowTotalWeight() {
      if (!this.weightFeatureAvailable) {
        return false;
      }

      if (this.isEpicBoard) {
        return this.glFeatures.feEpicBoardTotalWeight && !this.isEpicBoardListLoading;
      }

      return !this.isLoading;
    },
  },
  watch: {
    boardList: {
      handler() {
        this.setFullBoardIssuesCount({
          listId: this.boardList?.id,
          count: this.boardList?.issuesCount ?? 0,
        });
      },
    },
  },
  methods: {
    ...mapActions(['setFullBoardIssuesCount']),
  },
};
</script>
