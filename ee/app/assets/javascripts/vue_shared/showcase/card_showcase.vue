<script>
import { GlButton, GlCard, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlCard,
    GlIcon,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    primaryAction: {
      type: String,
      required: false,
      default: '',
    },
    primaryLink: {
      type: String,
      required: false,
      default: '',
    },
    primaryLinkIcon: {
      type: String,
      required: false,
      default: '',
    },
    primaryTrackingLabel: {
      type: String,
      required: false,
      default: '',
    },
    primaryTrackingProperty: {
      type: String,
      required: false,
      default: '',
    },
    secondaryAction: {
      type: String,
      required: false,
      default: '',
    },
    secondaryLink: {
      type: String,
      required: false,
      default: '',
    },
    secondaryLinkIcon: {
      type: String,
      required: false,
      default: '',
    },
    secondaryTrackingLabel: {
      type: String,
      required: false,
      default: '',
    },
    secondaryTrackingProperty: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="col-lg-3 gl-p-0 gl-mb-5">
    <gl-card class="gl-mr-5">
      <div class="gl-flex-direction-row">
        <div class="gl-mb-3">
          <strong class="gl-text-gray-800 gl-mb-2">
            {{ title }}
          </strong>
        </div>
        <p class="gl-font-sm">
          {{ description }}
        </p>
      </div>

      <div class="gl-bottom-0">
        <gl-button
          v-if="primaryAction"
          class="gl-mr-2"
          category="primary"
          variant="confirm"
          :href="primaryLink"
          target="_blank"
          data-testid="primary-button"
          data-track-="showcase_free_security_features"
          data-track-experiment="showcase_free_security_features"
          data-track-action="click_button"
          :data-track-label="primaryTrackingLabel"
          :data-track-property="primaryTrackingProperty"
        >
          {{ primaryAction }}
          <gl-icon v-if="primaryLinkIcon" :name="primaryLinkIcon" />
        </gl-button>

        <gl-button
          v-if="secondaryAction"
          class="gl-mr-2"
          category="secondary"
          variant="confirm"
          :href="secondaryLink"
          target="_blank"
          data-testid="secondary-button"
          data-track-experiment="showcase_free_security_features"
          data-track-action="click_button"
          :data-track-label="secondaryTrackingLabel"
          :data-track-property="secondaryTrackingProperty"
        >
          {{ secondaryAction }}
          <gl-icon v-if="secondaryLinkIcon" :name="secondaryLinkIcon" />
        </gl-button>
      </div>
    </gl-card>
  </div>
</template>
