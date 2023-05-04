import Draggable from 'vuedraggable';

import { defaultSortableOptions } from '~/sortable/constants';
import { ESC_KEY_CODE } from '~/lib/utils/keycodes';
import { idProp, relativePositions, treeItemChevronBtnClassName } from '../constants';

export default {
  computed: {
    treeRootWrapper() {
      return this.userSignedIn ? Draggable : 'ul';
    },
    treeRootOptions() {
      const options = {
        ...defaultSortableOptions,
        fallbackOnBody: false,
        group: 'sortable-container',
        tag: 'ul',
        'ghost-class': 'tree-item-drag-active',
        'data-parent-reference': this.parentItem.reference,
        'data-parent-id': this.parentItem.id,
        value: this.children,
        // This filters out/ignores all the chevron buttons (used for
        // expanding and collapsing epic tree items) so the drag action
        // can only be performed on the actual item card.
        filter: `.${treeItemChevronBtnClassName}`,
      };

      return this.userSignedIn ? options : {};
    },
  },
  methods: {
    /**
     * This method returns ID property's value for a given
     * item by accessing it using correct property name.
     *
     * Here's the name of id property for item types;
     *    Type `Epic` ->  `id`
     *    Type `Issue` ->  `epicIssueId`
     *
     * @param {object} item
     */
    getItemId(item) {
      return item[idProp[item.type]];
    },
    /**
     * This method returns an object containing
     *
     *  - `id` Global ID of target item.
     *  - `adjacentReferenceId` Global ID of adjacent item that's
     *                          either above or below new position of target item.
     *  - `relativePosition` String representation of adjacent item with respect to
     *                       target item, which can be either `before` or `after`.
     *
     * @param {number} object.newIndex new position of target item
     * @param {object} object.targetItem target item object
     */
    getTreeReorderMutation({ oldIndex, newIndex, targetItem }) {
      let relativePosition;

      // adjacentReference is always the item that's at the position
      // where target was moved.
      const adjacentReferenceId = this.getItemId(this.children[newIndex]);

      if (newIndex === 0) {
        // If newIndex is `0`, item was moved to the top.
        // Adjacent reference will be the one which is currently at the top,
        // and it's relative position with respect to target's new position is `after`.
        relativePosition = relativePositions.After;
      } else if (newIndex === this.children.length - 1) {
        // If newIndex is last position in list, item was moved to the bottom.
        // Adjacent reference will be the one which is currently at the bottom,
        // and it's relative position with respect to target's new position is `before`.
        relativePosition = relativePositions.Before;
      } else if (oldIndex < newIndex) {
        // If newIndex is neither top nor bottom, it was moved somewhere in the middle.
        // Adjacent reference will be the one which currently at that position,

        // when the item is moved down, the newIndex is before the adjacent reference.
        relativePosition = relativePositions.Before;
      } else {
        // when the item is moved up, the newIndex is after the adjacent reference.
        relativePosition = relativePositions.After;
      }

      return {
        id: this.getItemId(targetItem),
        adjacentReferenceId,
        relativePosition,
      };
    },
    /**
     * This event handler is triggered the moment dragging
     * of item is started, and it sets `is-dragging` class
     * to page body.
     */
    handleDragOnStart() {
      document.body.classList.add('is-dragging');

      this.dragCancelled = false;
      // Attach listener to detect `ESC` key press to cancel drag.
      document.addEventListener('keyup', this.handleKeyUp.bind(this));
    },
    /**
     * This event handler is fired when user releases the dragging
     * item.
     *
     * This method actually fires Vuex action `reorderItem`
     * that performs GraphQL mutation to update item order
     * within tree.
     *
     * @param {object} event Object representing drag end event.
     */
    handleDragOnEnd(params) {
      const { oldIndex, newIndex, from, to } = params;
      document.body.classList.remove('is-dragging');

      // Detach listener as soon as drag ends.
      document.removeEventListener('keyup', this.handleKeyUp.bind(this));
      // Drag was cancelled, prevent reordering.
      if (this.dragCancelled) return;

      const targetItem = this.children[oldIndex];

      if (from === to) {
        // If both old and new index of target are same,
        // nothing was moved, we do an early return.
        if (oldIndex === newIndex) return;

        this.reorderItem({
          treeReorderMutation: this.getTreeReorderMutation({ oldIndex, newIndex, targetItem }),
          parentItem: this.parentItem,
          targetItem,
          oldIndex,
          newIndex,
        });
      } else {
        this.moveItem({
          oldParentItem: this.parentItem,
          newParentItem: to.dataset,
          targetItem,
          oldIndex,
          newIndex,
        });
      }
    },
    handleKeyUp(e) {
      if (e.keyCode === ESC_KEY_CODE) {
        this.dragCancelled = true;
        // Sortable.js internally listens for `mouseup` event on document
        // to register drop event, see https://github.com/SortableJS/Sortable/blob/master/src/Sortable.js#L625
        // We need to manually trigger it to simulate cancel behaviour as VueDraggable doesn't
        // natively support it, see https://github.com/SortableJS/Vue.Draggable/issues/968.
        document.dispatchEvent(new Event('mouseup'));
      }
    },
  },
};
