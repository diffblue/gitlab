<script>
import { GlTooltipDirective, GlLoadingIcon, GlButton, GlIcon } from '@gitlab/ui';
import { mapGetters, mapActions, mapState } from 'vuex';

import { __ } from '~/locale';

import { ChildType } from '../constants';
import TreeItemBody from './tree_item_body.vue';

export default {
  ChildType,
  components: {
    GlIcon,
    TreeItemBody,
    GlLoadingIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['children', 'childrenFlags']),
    ...mapGetters(['anyParentHasChildren']),
    itemReference() {
      return this.item.reference;
    },
    hasChildren() {
      return this.childrenFlags[this.itemReference].itemHasChildren;
    },
    chevronType() {
      return this.childrenFlags[this.itemReference].itemExpanded ? 'chevron-down' : 'chevron-right';
    },
    chevronTooltip() {
      return this.childrenFlags[this.itemReference].itemExpanded ? __('Collapse') : __('Expand');
    },
    childrenFetchInProgress() {
      return this.hasChildren && this.childrenFlags[this.itemReference].itemChildrenFetchInProgress;
    },
    itemExpanded() {
      return this.hasChildren && this.childrenFlags[this.itemReference].itemExpanded;
    },
    hasNoChildren() {
      return (
        this.anyParentHasChildren &&
        !this.hasChildren &&
        !this.childrenFlags[this.itemReference].itemChildrenFetchInProgress
      );
    },
    showEpicDropzone() {
      return !this.hasChildren && this.item.type === ChildType.Epic;
    },
  },
  methods: {
    ...mapActions(['toggleItem']),
    handleChevronClick() {
      this.toggleItem({
        parentItem: this.item,
      });
    },
  },
};
</script>

<template>
  <li
    class="tree-item list-item gl-py-0"
    data-qa-selector="related_issue_item"
    :class="{
      'has-children': hasChildren,
      'item-expanded': childrenFlags[itemReference].itemExpanded,
      'js-item-type-epic item-type-epic': item.type === $options.ChildType.Epic,
      'js-item-type-issue item-type-issue': item.type === $options.ChildType.Issue,
    }"
  >
    <div class="list-item-body d-flex align-items-center">
      <gl-button
        v-if="!childrenFetchInProgress && hasChildren"
        v-gl-tooltip.viewport.hover
        :title="chevronTooltip"
        :aria-label="chevronTooltip"
        :class="chevronType"
        variant="link"
        class="btn-svg btn-tree-item-chevron align-self-start"
        @click="handleChevronClick"
      >
        <gl-icon :name="chevronType" />
      </gl-button>
      <gl-loading-icon v-if="childrenFetchInProgress" class="loading-icon" size="sm" />
      <tree-item-body
        class="tree-item-row gl-mb-3"
        :parent-item="parentItem"
        :item="item"
        :class="{
          'tree-item-noexpand': hasNoChildren,
        }"
      />
    </div>
    <tree-root
      v-if="itemExpanded || showEpicDropzone"
      :parent-item="item"
      :children="
        children[itemReference] ||
        [] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */
      "
      class="sub-tree-root"
    />
  </li>
</template>
