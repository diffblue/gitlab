<script>
import { GlModal } from '@gitlab/ui';
import { escape } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';

import { sprintf, __ } from '~/locale';

import { ChildType, RemoveItemModalProps, itemRemoveModalId } from '../constants';

export default {
  itemRemoveModalId,
  components: {
    GlModal,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapState(['childrenFlags', 'parentItem', 'removeItemModalProps']),
    removeItemType() {
      const removeItem = this.removeItemModalProps.item;
      if (
        removeItem.type === ChildType.Epic &&
        this.childrenFlags[removeItem.reference].itemHasChildren
      ) {
        return ChildType.EpicWithChildren;
      }
      return removeItem.type;
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

        if (
          this.removeItemType === ChildType.Epic ||
          this.removeItemType === ChildType.EpicWithChildren
        ) {
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
  modal: {
    actionPrimary: {
      text: __('Remove'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
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
    no-fade
    :action-primary="$options.modal.actionPrimary"
    :action-cancel="$options.modal.actionCancel"
    @primary="
      removeItem({
        parentItem: removeItemModalProps.parentItem,
        item: removeItemModalProps.item,
      })
    "
  >
    <p v-safe-html="modalBody"></p>
  </gl-modal>
</template>
