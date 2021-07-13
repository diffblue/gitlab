<script>
import { GlBanner } from '@gitlab/ui';
import { I18N } from '../constants';
import { isDismissed, dismiss, trackShow, trackCtaClicked } from '../utils';

export default {
  components: {
    GlBanner,
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
  i18n: I18N,
};
</script>

<template>
  <gl-banner
    v-if="isVisible"
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="sastDocumentationPath"
    variant="promotion"
    class="gl-my-5"
    @close="onDismiss"
    @primary="onClick"
  >
    <p>
      {{ $options.i18n.bodyText }}
    </p>
  </gl-banner>
</template>
