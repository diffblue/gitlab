<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { selectedRect as getSelectedRect } from 'prosemirror-tables';

export default {
  name: 'TableCellWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  props: {
    editor: {
      type: Object,
      required: true,
    },
    getPos: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      displayActionsDropdown: false,
      preventHide: true,
      selectedRect: null,
    };
  },
  computed: {
    totalRows() {
      return this.selectedRect?.map.height;
    },
    totalCols() {
      return this.selectedRect?.map.width;
    },
  },
  mounted() {
    this.editor.on('selectionUpdate', this.handleSelectionUpdate);
    this.handleSelectionUpdate();
  },
  beforeDestroy() {
    this.editor.off('selectionUpdate', this.handleSelectionUpdate);
  },
  methods: {
    handleSelectionUpdate() {
      const { state } = this.editor;
      const { $cursor } = state.selection;

      this.displayActionsDropdown = $cursor?.pos - $cursor?.parentOffset - 1 === this.getPos();
      if (this.displayActionsDropdown) {
        this.selectedRect = getSelectedRect(state);
      }
    },
    runCommand(command) {
      this.editor.chain()[command]().run();
      this.hideDropdown();
    },
    handleHide($event) {
      if (this.preventHide) {
        $event.preventDefault();
      }
      this.preventHide = true;
    },
    hideDropdown() {
      this.preventHide = false;
      this.$refs.dropdown?.hide();
    },
  },
};
</script>
<template>
  <node-view-wrapper class="gl-relative gl-padding-5" as="td" @click="hideDropdown">
    <span v-if="displayActionsDropdown" class="gl-absolute gl-right-0 gl-top-0">
      <gl-dropdown
        ref="dropdown"
        dropup
        icon="chevron-down"
        size="small"
        category="tertiary"
        boundary="viewport"
        no-caret
        :popper-opts="{ positionFixed: true }"
        @hide="handleHide($event)"
      >
        <gl-dropdown-item @click="runCommand('addColumnBefore')">
          {{ __('Insert column before') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addColumnAfter')">
          {{ __('Insert column after') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addRowBefore')">
          {{ __('Insert row before') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addRowAfter')">
          {{ __('Insert row after') }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
        <gl-dropdown-item v-if="totalRows > 2" @click="runCommand('deleteRow')">
          {{ __('Delete row') }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="totalCols > 1" @click="runCommand('deleteColumn')">
          {{ __('Delete column') }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('deleteTable')">
          {{ __('Delete table') }}
        </gl-dropdown-item>
      </gl-dropdown>
    </span>
    <node-view-content />
  </node-view-wrapper>
</template>
