<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { mapActions } from 'vuex';
import IssueBoardFilteredSearchFoss from '~/boards/components/issue_board_filtered_search.vue';
import { BoardType } from '~/boards/constants';
import { __ } from '~/locale';
import { OPERATOR_IS_AND_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import EpicToken from '~/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import IterationToken from '~/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  extends: IssueBoardFilteredSearchFoss,
  i18n: {
    ...IssueBoardFilteredSearchFoss.i18n,
    epic: __('Epic'),
    iteration: __('Iteration'),
  },
  mixins: [glFeatureFlagMixin()],
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
      const { epic, iteration } = this.$options.i18n;

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
        ...(this.glFeatures.iterationCadences
          ? [
              {
                icon: 'iteration',
                title: iteration,
                type: 'iteration',
                operators: OPERATOR_IS_AND_IS_NOT,
                token: IterationToken,
                unique: true,
                fetchIterations: this.fetchIterations,
              },
            ]
          : []),
      ];
    },
  },
  methods: {
    ...mapActions(['fetchIterations']),
  },
};
</script>
