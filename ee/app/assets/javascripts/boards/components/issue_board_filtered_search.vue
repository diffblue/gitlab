<script>
// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
/* eslint-disable @gitlab/no-runtime-template-compiler */
import { mapActions } from 'vuex';
import { orderBy } from 'lodash';
import IssueBoardFilteredSearchFoss from '~/boards/components/issue_board_filtered_search.vue';
import { BoardType } from '~/boards/constants';
import { __ } from '~/locale';
import { OPERATOR_IS_AND_IS_NOT } from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';

export default {
  extends: IssueBoardFilteredSearchFoss,
  i18n: {
    ...IssueBoardFilteredSearchFoss.i18n,
    epic: __('Epic'),
    iteration: __('Iteration'),
    weight: __('Weight'),
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['epicFeatureAvailable', 'iterationFeatureAvailable'],
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
      const { epic, iteration, weight } = this.$options.i18n;

      const tokens = [
        ...this.tokensCE,
        ...(this.epicFeatureAvailable
          ? [
              {
                type: 'epic',
                title: epic,
                icon: 'epic',
                token: EpicToken,
                unique: true,
                symbol: '&',
                idProperty: 'id',
                useIdValue: true,
                fullPath: this.epicsGroupPath,
              },
            ]
          : []),
        ...(this.iterationFeatureAvailable
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
        {
          type: 'weight',
          title: weight,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        },
      ];

      return orderBy(tokens, ['title']);
    },
  },
  methods: {
    ...mapActions(['fetchIterations']),
  },
};
</script>
