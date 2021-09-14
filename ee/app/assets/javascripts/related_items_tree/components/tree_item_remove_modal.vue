<script>
import { GlModal, GlSafeHtmlDirective } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapState, mapActions } from 'vuex';

import { sprintf } from '~/locale';

import { ChildType, RemoveItemModalProps, itemRemoveModalId } from '../constants';

export default {
  itemRemoveModalId,
  components: {
    GlModal,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  computed: {
    ...mapState(['parentItem', 'removeItemModalProps']),
    removeItemType() {
      return this.removeItemModalProps.item.type;
    },
    modalTitle() {
      return this.removeItemType ? RemoveItemModalProps[this.removeItemType].title : '';
    },
    modalBody() {
      if (this.removeItemType) {
        const sprintfParams = {
          bStart: '<b>',
          bEnd: '</b>',
        };

        if (this.removeItemType === ChildType.Epic) {
          Object.assign(sprintfParams, {
            targetEpicTitle: escape(this.removeItemModalProps.item.title),
            parentEpicTitle: escape(this.parentItem.title),
          });
        } else {
          Object.assign(sprintfParams, {
            targetIssueTitle: escape(this.removeItemModalProps.item.title),
            parentEpicTitle: escape(this.parentItem.title),
          });
        }

        return sprintf(RemoveItemModalProps[this.removeItemType].body, sprintfParams, false);
      }

      return '';
    },
  },
  methods: {
    ...mapActions(['removeItem']),
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.itemRemoveModalId"
    :title="modalTitle"
    :ok-title="__('Remove')"
    ok-variant="danger"
    no-fade
    @ok="
      removeItem({
        parentItem: removeItemModalProps.parentItem,
        item: removeItemModalProps.item,
      })
    "
  >
    <p v-safe-html="modalBody"></p>
  </gl-modal>
</template>
