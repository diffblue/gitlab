<script>
import { GlBanner } from '@gitlab/ui';
import { __ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import Tracking from '~/tracking';
import {
  TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION,
  TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
} from '~/security_configuration/constants';

export default {
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  mixins: [Tracking.mixin()],
  inject: ['securityConfigurationPath', 'projectFullPath'],
  i18n: {
    title: __('Reduce risk and triage fewer vulnerabilities with security training'),
    buttonText: __('Enable security training'),
    content: __(
      'Enable security training to help your developers learn how to fix vulnerabilities. Developers can view security training from selected educational providers, relevant to the detected vulnerability.',
    ),
  },
  computed: {
    buttonLink() {
      return `${this.securityConfigurationPath}?tab=vulnerability-management`;
    },
  },
  methods: {
    trackCTAClick() {
      this.track(TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION, {
        label: TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
        property: this.projectFullPath,
      });
    },
  },
};
</script>

<template>
  <user-callout-dismisser feature-name="security_training_feature_promotion">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        :title="$options.i18n.title"
        :button-text="$options.i18n.buttonText"
        :button-link="buttonLink"
        variant="introduction"
        @primary="trackCTAClick"
        @close="dismiss"
      >
        <p>{{ $options.i18n.content }}</p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
