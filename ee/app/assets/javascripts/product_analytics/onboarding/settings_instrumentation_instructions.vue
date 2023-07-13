<script>
import { GlButton, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import InstrumentationInstructionsSdkDetails from './components/instrumentation_instructions_sdk_details.vue';
import InstrumentationInstructions from './components/instrumentation_instructions.vue';

export default {
  name: 'ProductAnalyticsSettingsInstrumentationInstructions',
  components: {
    GlButton,
    GlLink,
    GlModal,
    GlSprintf,
    InstrumentationInstructionsSdkDetails,
    InstrumentationInstructions,
  },
  inject: {
    collectorHost: {
      type: String,
    },
  },
  props: {
    trackingKey: {
      type: String,
      required: false,
      default: null,
    },
    dashboardsPath: {
      type: String,
      required: true,
    },
    onboardingPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      modalIsVisible: false,
    };
  },
  methods: {
    showModal() {
      this.modalIsVisible = true;
    },
    onModalChange(isVisible) {
      this.modalIsVisible = isVisible;
    },
  },
  i18n: {
    instrumentYourAppTitle: s__('ProjectSettings|Instrument your application'),
    setUpProductAnalytics: s__(
      'ProjectSettings|You need to %{linkStart}set up product analytics%{linkEnd} before your application can be instrumented.',
    ),
    viewInstrumentationInstructionsButton: s__(
      'ProjectSettings|Your project is set up. %{linkStart}View instrumentation instructions%{linkEnd}.',
    ),
    modalTitle: s__('ProjectSettings|Instrumentation details'),
    modalPrimaryButton: {
      text: __('Close'),
    },
  },
};
</script>
<template>
  <section class="gl-mb-5">
    <gl-sprintf v-if="!trackingKey" :message="$options.i18n.setUpProductAnalytics">
      <template #link="{ content }">
        <gl-link :href="onboardingPath" data-testid="onboarding-link">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
    <div v-else>
      <instrumentation-instructions-sdk-details :tracking-key="trackingKey" />

      <gl-sprintf :message="$options.i18n.viewInstrumentationInstructionsButton">
        <template #link="{ content }">
          <gl-button category="secondary" variant="link" @click="showModal">{{
            content
          }}</gl-button>
        </template>
      </gl-sprintf>

      <gl-modal
        modal-id="analytics-instrumentation-instructions-modal"
        :title="$options.i18n.modalTitle"
        :action-primary="$options.i18n.modalPrimaryButton"
        :visible="modalIsVisible"
        size="lg"
        @change="onModalChange"
      >
        <instrumentation-instructions
          :dashboards-path="dashboardsPath"
          :tracking-key="trackingKey"
        />
      </gl-modal>
    </div>
  </section>
</template>
