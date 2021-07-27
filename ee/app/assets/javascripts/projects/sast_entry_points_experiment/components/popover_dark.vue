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
  gitlabLogo: window.gon.gitlab_logo,
  i18n: I18N,
};
</script>

<template>
  <gl-popover
    v-if="isVisible"
    :target="target"
    show
    triggers="manual"
    placement="bottomright"
    :css-classes="['marketing-popover', 'gl-border-4']"
  >
    <div class="gl-display-flex gl-mt-n2">
      <img :src="$options.gitlabLogo" :alt="''" height="24" width="24" class="gl-ml-2 gl-mr-3" />
      <div>
        <div
          class="gl-font-weight-bold gl-font-lg gl-line-height-20 gl-text-theme-indigo-900 gl-mb-3"
        >
          {{ $options.i18n.title }}
        </div>
        <div class="gl-font-base gl-line-height-20 gl-mb-3">
          {{ $options.i18n.bodyText }}
        </div>
        <gl-link :href="sastDocumentationPath" @click="onClick">
          {{ $options.i18n.linkText }}
        </gl-link>
      </div>
      <gl-button
        category="tertiary"
        class="gl-align-self-start gl-mt-n3 gl-mr-n3"
        icon="close"
        :aria-label="__('Close')"
        @click="onDismiss"
      />
    </div>
  </gl-popover>
</template>
