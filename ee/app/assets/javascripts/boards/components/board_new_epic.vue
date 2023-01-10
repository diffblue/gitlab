<script>
import { mapActions, mapState } from 'vuex';
import BoardNewItem from '~/boards/components/board_new_item.vue';
import { toggleFormEventPrefix } from '~/boards/constants';
import eventHub from '~/boards/eventhub';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import GroupSelect from './group_select.vue';

export default {
  components: {
    BoardNewItem,
    GroupSelect,
  },
  inject: ['fullPath'],
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['selectedGroup']),
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
    <group-select :list="list" />
  </board-new-item>
</template>
