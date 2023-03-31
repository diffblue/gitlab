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
    popoverId: {
      type: String,
      required: true,
    },
    iconName: {
      type: String,
      required: false,
      default: 'question-o',
    },
  },
};
</script>

<template>
  <span class="gl-display-inline-flex gl-ml-2 js-help">
    <gl-icon
      :id="popoverId"
      :name="iconName"
      class="author-link gl-cursor-help"
      :aria-label="__('help')"
      :size="14"
      data-testid="icon2"
    />
    <gl-popover :target="popoverId" placement="top" :title="title">
      <div class="gl-mb-3">{{ text }}</div>
      <gl-link v-if="documentationLink" target="_blank" :href="documentationLink">
        <span class="vertical-align-middle">{{ documentationText }}</span>
        <gl-icon name="external-link" class="gl-vertical-align-middle" />
      </gl-link>
    </gl-popover>
  </span>
</template>
