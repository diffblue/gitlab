<script>
import { orderBy } from 'lodash';
import IssueBoardFilteredSearchFoss from '~/boards/components/issue_board_filtered_search.vue';
import {
  OPERATORS_IS_NOT,
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_HEALTH,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_WEIGHT,
} from 'ee/vue_shared/components/filtered_search_bar/constants';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';
import HealthToken from 'ee/vue_shared/components/filtered_search_bar/tokens/health_token.vue';
import IterationToken from 'ee/vue_shared/components/filtered_search_bar/tokens/iteration_token.vue';
import WeightToken from 'ee/vue_shared/components/filtered_search_bar/tokens/weight_token.vue';
import issueBoardFilters from '../issue_board_filters';

// This is a false violation of @gitlab/no-runtime-template-compiler, since it
// extends a valid Vue single file component.
// eslint-disable-next-line @gitlab/no-runtime-template-compiler
export default {
  extends: IssueBoardFilteredSearchFoss,
  i18n: {
    ...IssueBoardFilteredSearchFoss.i18n,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'epicFeatureAvailable',
    'iterationFeatureAvailable',
    'healthStatusFeatureAvailable',
    'isGroupBoard',
  ],
  computed: {
    epicsGroupPath() {
      return this.isGroupBoard
        ? this.fullPath
        : this.fullPath.slice(0, this.fullPath.lastIndexOf('/'));
    },
    tokens() {
      const { fetchIterations, fetchIterationCadences } = issueBoardFilters(
        this.$apollo,
        this.fullPath,
        this.isGroupBoard,
      );

      const tokens = [
        ...this.tokensCE,
        ...(this.epicFeatureAvailable
          ? [
              {
                type: TOKEN_TYPE_EPIC,
                title: TOKEN_TITLE_EPIC,
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
                title: TOKEN_TITLE_ITERATION,
                type: TOKEN_TYPE_ITERATION,
                operators: OPERATORS_IS_NOT,
                token: IterationToken,
                unique: true,
                fetchIterations,
                fetchIterationCadences,
              },
            ]
          : []),
        {
          type: TOKEN_TYPE_WEIGHT,
          title: TOKEN_TITLE_WEIGHT,
          icon: 'weight',
          token: WeightToken,
          unique: true,
        },
        ...(this.healthStatusFeatureAvailable
          ? [
              {
                type: TOKEN_TYPE_HEALTH,
                title: TOKEN_TITLE_HEALTH,
                icon: 'status-health',
                operators: OPERATORS_IS_NOT,
                token: HealthToken,
                unique: false,
              },
            ]
          : []),
      ];

      return orderBy(tokens, ['title']);
    },
  },
};
</script>
