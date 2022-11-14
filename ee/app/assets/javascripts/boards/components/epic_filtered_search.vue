<script>
import { orderBy } from 'lodash';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import issueBoardFilter from '~/boards/issue_board_filters';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import {
  OPERATOR_IS_AND_IS_NOT,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

export default {
  components: { BoardFilteredSearch },
  inject: ['fullPath', 'boardType'],
  computed: {
    tokens() {
      const { fetchLabels, fetchAuthors } = issueBoardFilter(
        this.$apollo,
        this.fullPath,
        this.boardType,
      );

      const tokens = [
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          operators: OPERATOR_IS_AND_IS_NOT,
          token: LabelToken,
          unique: false,
          symbol: '~',
          defaultLabels: [{ value: __('No label'), text: __('No label') }],
          fetchLabels,
        },
        {
          icon: 'pencil',
          title: TOKEN_TITLE_AUTHOR,
          type: TOKEN_TYPE_AUTHOR,
          operators: OPERATOR_IS_AND_IS_NOT,
          symbol: '@',
          token: AuthorToken,
          unique: true,
          fetchAuthors,
          preloadedAuthors: this.preloadedAuthors(),
        },
      ];

      return orderBy(tokens, ['title']);
    },
  },
  methods: {
    preloadedAuthors() {
      return gon?.current_user_id
        ? [
            {
              id: convertToGraphQLId(TYPE_USER, gon.current_user_id),
              name: gon.current_user_fullname,
              username: gon.current_username,
              avatarUrl: gon.current_user_avatar_url,
            },
          ]
        : [];
    },
  },
};
</script>

<template>
  <board-filtered-search data-testid="epic-filtered-search" :tokens="tokens" />
</template>
