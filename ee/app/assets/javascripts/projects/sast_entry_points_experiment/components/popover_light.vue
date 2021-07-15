<script>
import { GlPopover, GlButton, GlLink } from '@gitlab/ui';
import { I18N, POPOVER_TARGET } from '../constants';
import { isDismissed, dismiss, trackShow, trackCtaClicked, trackDismissed } from '../utils';

export default {
  components: {
    GlPopover,
    GlButton,
    GlLink,
  },
  props: {
    sastDocumentationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isVisible: !isDismissed(),
      target: document.querySelector(POPOVER_TARGET),
    };
  },
  mounted() {
    if (this.isVisible) {
      trackShow();
    }
  },
  methods: {
    onDismiss() {
      this.isVisible = false;
      dismiss();
      trackDismissed();
    },
    onClick() {
      dismiss();
      trackCtaClicked();
    },
  },
  i18n: I18N,
};
</script>

<template>
  <gl-popover v-if="isVisible" :target="target" show triggers="manual" placement="bottomright">
    <template #title>
      <div class="gl-display-flex">
        <span>
          {{ $options.i18n.title }}
          <gl-emoji class="gl-ml-2" data-name="raised_hands" />
        </span>
        <gl-button
          category="tertiary"
          class="gl-align-self-start close gl-opacity-10"
          icon="close"
          :aria-label="__('Close')"
          @click="onDismiss"
        />
      </div>
    </template>
    {{ $options.i18n.bodyText }}
    <div class="gl-text-right gl-font-weight-bold">
      <gl-link :href="sastDocumentationPath" @click="onClick">
        {{ $options.i18n.linkText }}
      </gl-link>
    </div>
  </gl-popover>
</template>
