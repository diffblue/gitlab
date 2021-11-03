<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import IssueBoardFilteredSearchFoss from '~/boards/components/issue_board_filtered_search.vue';
import { BoardType } from '~/boards/constants';
import { __ } from '~/locale';
import EpicToken from '~/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';

export default {
  extends: IssueBoardFilteredSearchFoss,
  i18n: {
    ...IssueBoardFilteredSearchFoss.i18n,
    epic: __('Epic'),
  },
  computed: {
    isGroupBoard() {
      return this.boardType === BoardType.group;
    },
    epicsGroupPath() {
      return this.isGroupBoard
        ? this.fullPath
        : this.fullPath.slice(0, this.fullPath.lastIndexOf('/'));
    },
    tokens() {
      const { epic } = this.$options.i18n;

      return [
        ...this.tokensCE,
        {
          type: 'epic_id',
          title: epic,
          icon: 'epic',
          token: EpicToken,
          unique: true,
          symbol: '&',
          idProperty: 'id',
          useIdValue: true,
          fullPath: this.epicsGroupPath,
        },
      ];
    },
  },
};
</script>
