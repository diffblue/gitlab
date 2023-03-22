<script>
import { GlTooltipDirective, GlButton, GlIcon } from '@gitlab/ui';
import NoteHeader from '~/notes/components/note_header.vue';

export default {
  name: 'EventItem',
  components: {
    GlIcon,
    NoteHeader,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    id: {
      type: [String, Number],
      required: false,
      default: undefined,
    },
    author: {
      type: Object,
      required: true,
    },
    createdAt: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: 'plus',
    },
    iconClass: {
      type: String,
      required: false,
      default: 'ci-status-icon-success',
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    showRightSlot: {
      type: Boolean,
      required: false,
      default: false,
    },
    showActionButtons: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    noteId() {
      return this.id ? `note_${this.id}` : undefined;
    },
  },
};
</script>

<template>
  <div :id="noteId" class="gl-display-flex gl-align-items-center">
    <div class="circle-icon-container gl-flex-shrink-0 gl-align-self-start" :class="iconClass">
      <gl-icon :size="16" :name="iconName" />
    </div>
    <div class="gl-ml-5 gl-flex-grow-1" data-qa-selector="event_item_content">
      <note-header
        :note-id="id"
        :author="author"
        :created-at="createdAt"
        :show-spinner="false"
        class="gl-pb-0 gl-pl-0"
      >
        <slot name="header-message"><template v-if="createdAt">&middot;</template></slot>
      </note-header>

      <slot></slot>
    </div>

    <slot v-if="showRightSlot" name="right-content"></slot>

    <div
      v-else-if="showActionButtons"
      class="gl-flex-shrink-0 gl-align-self-start"
      data-testid="action-buttons"
    >
      <gl-button
        v-for="button in actionButtons"
        :key="button.title"
        v-gl-tooltip
        category="tertiary"
        :icon="button.iconName"
        :title="button.title"
        :aria-label="button.title"
        @click="button.onClick"
      />
    </div>
  </div>
</template>
