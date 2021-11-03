<script>
import { GlLink, GlPopover, GlIcon } from '@gitlab/ui';

export default {
  name: 'ApprovalCheckPopover',
  components: {
    GlLink,
    GlPopover,
    GlIcon,
  },
  props: {
    documentationLink: {
      type: String,
      required: false,
      default: '',
    },
    documentationText: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    popoverTriggerId() {
      return `reportInfo-${this.title}`;
    },
  },
};
</script>

<template>
  <span class="vertical-align-middle text-muted js-help ml-2">
    <gl-icon
      :id="popoverTriggerId"
      name="question"
      class="author-link gl-cursor-help"
      :aria-label="__('help')"
      :size="14"
      data-testid="icon2"
    />
    <gl-popover :target="popoverTriggerId" placement="top" :title="title">
      <div class="mb-2">{{ text }}</div>
      <gl-link v-if="documentationLink" target="_blank" :href="documentationLink">
        <span class="vertical-align-middle">{{ documentationText }}</span>
        <gl-icon name="external-link" class="vertical-align-middle" />
      </gl-link>
    </gl-popover>
  </span>
</template>
