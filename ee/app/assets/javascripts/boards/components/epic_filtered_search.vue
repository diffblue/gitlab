<script>
import { orderBy } from 'lodash';
import BoardFilteredSearch from 'ee/boards/components/board_filtered_search.vue';
import issueBoardFilters from '~/boards/issue_board_filters';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import {
  OPERATORS_IS_NOT,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

export default {
  components: { BoardFilteredSearch },
  inject: ['fullPath', 'boardType', 'isGroupBoard'],
  props: {
    board: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  computed: {
    tokens() {
      const { fetchLabels, fetchUsers } = issueBoardFilters(
        this.$apollo,
        this.fullPath,
        this.isGroupBoard,
      );

      const tokens = [
        {
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          type: TOKEN_TYPE_LABEL,
          operators: OPERATORS_IS_NOT,
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
          operators: OPERATORS_IS_NOT,
          symbol: '@',
          token: UserToken,
          unique: true,
          fetchUsers,
          preloadedUsers: this.preloadedUsers(),
        },
      ];

      return orderBy(tokens, ['title']);
    },
  },
  methods: {
    preloadedUsers() {
      return gon?.current_user_id
        ? [
            {
              id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
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
  <board-filtered-search
    data-testid="epic-filtered-search"
    :tokens="tokens"
    :board="board"
    @setFilters="$emit('setFilters', $event)"
  />
</template>
