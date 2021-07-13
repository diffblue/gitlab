<script>
import { GlPopover, GlButton } from '@gitlab/ui';
import { I18N, POPOVER_TARGET } from '../constants';
import { isDismissed, dismiss, trackShow, trackCtaClicked } from '../utils';

export default {
  components: {
    GlPopover,
    GlButton,
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
    },
    onClick() {
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
    offset="93"
    :css-classes="['marketing-popover', 'gl-border-4', 'gl-border-t-solid']"
  >
    <div class="gl-display-flex gl-mt-n2">
      <img :src="$options.gitlabLogo" height="24" width="24" class="gl-ml-2 gl-mr-3" />
      <div>
        <div
          class="gl-font-weight-bold gl-font-lg gl-line-height-20 gl-text-theme-indigo-900 gl-mb-3"
        >
          {{ $options.i18n.title }}
        </div>
        <div class="gl-font-base gl-line-height-20 gl-mb-3">
          {{ $options.i18n.bodyText }}
        </div>
        <gl-button variant="link" :href="sastDocumentationPath" @click="onClick">
          {{ $options.i18n.linkText }}
        </gl-button>
      </div>
      <gl-button
        category="tertiary"
        class="gl-align-self-start gl-mt-n3 gl-mr-n3"
        icon="close"
        data-testid="close-btn"
        :aria-label="__('Close')"
        @click="onDismiss"
      />
    </div>
  </gl-popover>
</template>
