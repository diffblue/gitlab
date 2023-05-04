<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

import { ChildType, EXPAND_DELAY } from '../constants';
import TreeDragAndDropMixin from '../mixins/tree_dd_mixin';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  mixins: [TreeDragAndDropMixin],
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    children: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      dragCancelled: false,
      fetchInProgress: false,
      currentClientX: 0,
      currentClientY: 0,
    };
  },
  computed: {
    ...mapState(['childrenFlags', 'userSignedIn']),
    hasMoreChildren() {
      const flags = this.childrenFlags[this.parentItem.reference];

      return flags.hasMoreEpics || flags.hasMoreIssues;
    },
  },
  methods: {
    ...mapActions(['fetchNextPageItems', 'reorderItem', 'moveItem', 'toggleItem']),
    handleShowMoreClick() {
      this.fetchInProgress = true;
      this.fetchNextPageItems({
        parentItem: this.parentItem,
      })
        .then(() => {
          this.fetchInProgress = false;
        })
        .catch(() => {
          this.fetchInProgress = false;
        });
    },
    onMove(e, originalEvent) {
      const item = e.relatedContext.element;
      const { clientX, clientY } = originalEvent;

      // Cache current cursor position
      this.currentClientX = clientX;
      this.currentClientY = clientY;

      // Check if current item is an Epic, and has any children.
      if (item?.type === ChildType.Epic && (item.hasChildren || item.hasIssues)) {
        const { top, left } = originalEvent.target.getBoundingClientRect();

        // Check if user has paused cursor on top of current item's boundary
        if (clientY >= top && clientX >= left) {
          // Wait for moment before expanding the epic
          this.toggleTimer = setTimeout(() => {
            // Ensure that current cursor position is still within item's boundary
            if (this.currentClientX === clientX && this.currentClientY === clientY) {
              this.toggleItem({
                parentItem: item,
                isDragging: true,
              });
            }
          }, EXPAND_DELAY);
        } else {
          clearTimeout(this.toggleTimer);
        }
      }
    },
  },
};
</script>

<template>
  <component
    :is="treeRootWrapper"
    v-bind="treeRootOptions"
    class="list-unstyled related-items-list tree-root gl-p-0 gl-px-4"
    :move="onMove"
    @start="handleDragOnStart"
    @end="handleDragOnEnd"
  >
    <tree-item
      v-for="item in children"
      :key="item.id"
      :parent-item="parentItem"
      :item="item"
      class="gl-pt-3! gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
    />
    <li v-if="hasMoreChildren" class="tree-item list-item pt-0 pb-0 d-flex justify-content-center">
      <gl-button
        v-if="!fetchInProgress"
        class="d-inline-block mb-2"
        category="tertiary"
        variant="info"
        @click="handleShowMoreClick($event)"
        >{{ __('Show more') }}</gl-button
      >
      <gl-loading-icon v-else size="sm" class="mt-1 mb-1" />
    </li>
  </component>
</template>
