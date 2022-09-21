<script>
import { __ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import Tracking from '~/tracking';
import {
  TRACK_PROMOTION_BANNER_CTA_CLICK_ACTION,
  TRACK_PROMOTION_BANNER_CTA_CLICK_LABEL,
} from '~/security_configuration/constants';

export default {
  components: {
    UserCalloutDismisser,
  },
  mixins: [Tracking.mixin()],
  props: {
    securityConfigurationPath: {
      type: String,
      required: true,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    buttonText: __('Enable security training'),
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
      <slot
        v-if="shouldShowCallout"
        v-bind="{
          dismiss,
          buttonLink,
          buttonText: $options.i18n.buttonText,
          trackCTAClick,
        }"
      ></slot>
    </template>
  </user-callout-dismisser>
</template>
