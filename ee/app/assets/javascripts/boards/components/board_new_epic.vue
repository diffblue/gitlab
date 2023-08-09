<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { s__ } from '~/locale';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import { toggleFormEventPrefix } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import { setError } from '~/boards/graphql/cache_updates';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import epicBoardQuery from '../graphql/epic_board.query.graphql';

import GroupSelect from './group_select.vue';

export default {
  i18n: {
    errorFetchingBoard: s__('Boards|An error occurred while fetching board. Please try again.'),
  },
  components: {
    BoardNewItem,
    GroupSelect,
  },
  inject: ['boardType', 'fullPath', 'isApolloBoard'],
  props: {
    list: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedGroup: {},
    };
  },
  apollo: {
    board: {
      query() {
        return epicBoardQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          boardId: this.boardId,
        };
      },
      skip() {
        return !this.isApolloBoard;
      },
      update(data) {
        const { board } = data.workspace;
        return {
          ...board,
          labels: board.labels?.nodes,
        };
      },
      error(error) {
        setError({
          error,
          message: this.$options.i18n.errorFetchingBoard,
        });
      },
    },
  },
  computed: {
    formEventPrefix() {
      return toggleFormEventPrefix.epic;
    },
    formEvent() {
      return `${this.formEventPrefix}${this.list.id}`;
    },
    groupPath() {
      return this.selectedGroup?.fullPath ?? this.fullPath;
    },
  },
  methods: {
    ...mapActions(['addListNewEpic']),
    submit({ title }) {
      const labels = this.list.label ? [this.list.label] : [];

      if (this.isApolloBoard) {
        return this.addNewEpicToList({
          epicInput: {
            title,
            labelIds: labels?.map((l) => getIdFromGraphQLId(l.id)),
            groupPath: this.groupPath,
          },
        });
      }
      return this.addListNewEpic({
        epicInput: {
          title,
          labelIds: labels?.map((l) => getIdFromGraphQLId(l.id)),
          groupPath: this.groupPath,
        },
        list: this.list,
      }).then(() => {
        eventHub.$emit(this.formEvent);
      });
    },
    addNewEpicToList({ epicInput }) {
      const { labelIds = [], ...restEpicInput } = epicInput;
      const { labels } = this.board;
      const boardLabelIds = labels.map(({ id }) => getIdFromGraphQLId(id));

      this.$emit('addNewEpic', {
        ...restEpicInput,
        addLabelIds: [...labelIds, ...boardLabelIds],
      });
    },
    cancel() {
      eventHub.$emit(this.formEvent);
    },
  },
};
</script>

<template>
  <board-new-item
    :list="list"
    :form-event-prefix="formEventPrefix"
    :submit-button-title="__('Create epic')"
    @form-submit="submit"
    @form-cancel="cancel"
  >
    <group-select v-model="selectedGroup" :list="list" />
  </board-new-item>
</template>
