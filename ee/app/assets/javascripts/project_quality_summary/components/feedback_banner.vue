<script>
import { GlBanner } from '@gitlab/ui';
import { parseBoolean, getCookie, setCookie } from '~/lib/utils/common_utils';
import { i18n, FEEDBACK_ISSUE_URL, BANNER_DISMISSED_COOKIE_KEY } from '../constants';

export default {
  components: {
    GlBanner,
  },
  inject: {
    projectQualitySummaryFeedbackImagePath: {
      default: 'illustrations/chat-bubble-sm.svg',
    },
  },
  data() {
    return {
      bannerDismissed: parseBoolean(getCookie(BANNER_DISMISSED_COOKIE_KEY)),
    };
  },
  methods: {
    dismissBanner() {
      setCookie(BANNER_DISMISSED_COOKIE_KEY, 'true');
      this.bannerDismissed = true;
    },
  },
  FEEDBACK_ISSUE_URL,
  i18n,
};
</script>
<template>
  <gl-banner
    v-if="!bannerDismissed"
    class="gl-mt-6"
    :title="$options.i18n.banner.title"
    :button-text="$options.i18n.banner.button"
    :button-link="$options.FEEDBACK_ISSUE_URL"
    :svg-path="projectQualitySummaryFeedbackImagePath"
    @close="dismissBanner"
  >
    <p>{{ $options.i18n.banner.text }}</p>
  </gl-banner>
</template>
