<script>
import { mapActions } from 'vuex';
import BoardListHeaderFoss from '~/boards/components/board_list_header.vue';
import { n__, __, sprintf } from '~/locale';
import { listsDeferredQuery } from '../constants';

// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
// eslint-disable-next-line @gitlab/no-runtime-template-compiler
export default {
  extends: BoardListHeaderFoss,
  inject: ['weightFeatureAvailable', 'isEpicBoard', 'issuableType'],
  apollo: {
    boardList: {
      query() {
        return listsDeferredQuery[this.issuableType].query;
      },
      variables() {
        return {
          id: this.list.id,
          filters: this.filterParams,
        };
      },
      context: {
        isSingleRequest: true,
      },
      update(data) {
        return this.isEpicBoard ? data.epicBoardList : data.boardList;
      },
    },
  },
  computed: {
    countIcon() {
      return this.isEpicBoard ? 'epic' : 'issues';
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
    totalWeight() {
      if (this.isEpicBoard) {
        return this.boardList?.metadata?.totalWeight || 0;
      }

      return this.boardList?.totalWeight;
    },
  },
  watch: {
    boardList: {
      handler() {
        if (!this.isEpicBoard) {
          this.setFullBoardIssuesCount({
            listId: this.boardList?.id,
            count: this.boardList?.issuesCount ?? 0,
          });
        }
      },
    },
  },
  methods: {
    ...mapActions(['setFullBoardIssuesCount']),
  },
};
</script>
