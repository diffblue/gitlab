<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import SecurityTrainingPromo from 'ee/vue_shared/security_reports/components/security_training_promo.vue';

export const i18n = {
  title: s__('SecurityTraining|Resolve with security training'),
  content: s__(
    'SecurityTraining|Enable security training to learn how to fix vulnerabilities. View security training from selected educational providers relevant to the detected vulnerability.',
  ),
  buttonCancel: __("Don't show again"),
};

export default {
  i18n,
  components: {
    GlIcon,
    GlButton,
    SecurityTrainingPromo,
  },
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
};
</script>

<template>
  <security-training-promo
    :security-configuration-path="securityConfigurationPath"
    :project-full-path="projectFullPath"
  >
    <template #default="{ buttonLink, buttonText, dismiss, trackCTAClick }">
      <div class="gl-p-5 gl-bg-gray-50 gl-border-gray-100 gl-border-t gl-mx-n5 gl-display-flex">
        <gl-icon
          :size="16"
          name="bulb"
          class="gl-ml-2 gl-mr-4 gl-mt-1 gl-text-gray-600 gl-flex-shrink-0"
        />
        <div>
          <div class="gl-font-weight-bold">{{ $options.i18n.title }}</div>
          <p class="gl-mb-3">{{ $options.i18n.content }}</p>
          <div class="gl-display-inline-flex gl-flex-wrap gl-gap-3">
            <gl-button
              class="gl-flex-grow-1"
              variant="confirm"
              :href="buttonLink"
              data-testid="enableButton"
              @click="trackCTAClick"
            >
              {{ buttonText }}
            </gl-button>
            <gl-button
              category="secondary"
              class="gl-flex-grow-1"
              data-testid="cancelButton"
              @click="dismiss"
            >
              {{ $options.i18n.buttonCancel }}
            </gl-button>
          </div>
        </div>
      </div>
    </template>
  </security-training-promo>
</template>
