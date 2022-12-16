<script>
import { GlBanner, GlLink, GlSprintf } from '@gitlab/ui';
import {
  addActivationCode,
  subscriptionBannerBlogPostUrl,
  subscriptionBannerText,
  subscriptionBannerTitle,
} from '../constants';

export const ACTIVATE_SUBSCRIPTION_EVENT = 'activate-subscription';
export const CLOSE_ACTIVATE_SUBSCRIPTION_BANNER_EVENT = 'close';

export default {
  name: 'SubscriptionActivationBanner',
  subscriptionBannerBlogPostUrl,
  i18n: {
    bannerText: subscriptionBannerText,
    buttonText: addActivationCode,
    title: subscriptionBannerTitle,
  },
  components: {
    GlBanner,
    GlLink,
    GlSprintf,
  },
  inject: ['congratulationSvgPath', 'customersPortalUrl'],
  methods: {
    handleClose() {
      this.$emit(CLOSE_ACTIVATE_SUBSCRIPTION_BANNER_EVENT);
    },
    handlePrimary() {
      this.$emit(ACTIVATE_SUBSCRIPTION_EVENT);
    },
  },
};
</script>

<template>
  <gl-banner
    :button-text="$options.i18n.buttonText"
    :title="$options.i18n.title"
    variant="promotion"
    :svg-path="congratulationSvgPath"
    @close="handleClose"
    @primary="handlePrimary"
  >
    <p>
      <gl-sprintf :message="$options.i18n.bannerText">
        <template #blogPostLink="{ content }">
          <gl-link :href="$options.subscriptionBannerBlogPostUrl" target="_blank">{{
            content
          }}</gl-link>
        </template>
        <template #portalLink="{ content }">
          <gl-link :href="customersPortalUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </gl-banner>
</template>
