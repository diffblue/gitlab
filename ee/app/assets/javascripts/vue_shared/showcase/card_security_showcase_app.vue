<script>
import { helpPagePath } from '~/helpers/help_page_helper';
import CardShowcase from './card_showcase.vue';
import { SHOWCASE_CARDS, SHOWCASE_SECTIONS } from './constants';

export default {
  components: {
    CardShowcase,
  },
  inject: [
    'billingVulnerabilityManagement',
    'billingDependencyScanning',
    'billingDast',
    'billingContainerScanning',
    'trialVulnerabilityManagement',
    'trialDependencyScanning',
    'trialDast',
    'trialContainerScanning',
  ],
  i18n: {
    ...SHOWCASE_CARDS,
    ...SHOWCASE_SECTIONS,
  },
  sastHelpPage: helpPagePath('user/application_security/sast/index.md', {
    anchor: 'configuration',
  }),
  secretDetectionHelpPage: helpPagePath('user/application_security/secret_detection/index.md', {
    anchor: 'configuration',
  }),
};
</script>

<template>
  <div class="gl-my-5">
    <div class="gl-mb-4 col-lg-6 col-xs-12 gl-p-0">
      <h2 class="gl-col-12 gl-font-size-h2 gl-text-gray-900">
        {{ $options.i18n.identify.title }}
      </h2>
      <p class="gl-col-12 gl-text-gray-800">
        {{ $options.i18n.identify.description }}
      </p>
    </div>

    <div class="gl-display-flex gl-w-full gl-flex-flow-row-wrap">
      <card-showcase
        :title="$options.i18n.sast.title"
        :description="$options.i18n.sast.description"
        :primary-action="$options.i18n.sast.primaryAction"
        :primary-link="$options.sastHelpPage"
        primary-tracking-label="enable_sast"
        primary-link-icon="external-link"
      />
      <card-showcase
        :title="$options.i18n.secret_detection.title"
        :description="$options.i18n.secret_detection.description"
        :primary-action="$options.i18n.secret_detection.primaryAction"
        :primary-link="$options.secretDetectionHelpPage"
        primary-tracking-label="enable_secret_detection"
        primary-link-icon="external-link"
      />
    </div>

    <div class="gl-mb-4 col-lg-6 col-xs-12 gl-p-0">
      <h2 class="gl-col-12 gl-font-size-h2 gl-text-gray-900">
        {{ $options.i18n.takeNextLevel.title }}
      </h2>
      <p class="gl-col-12 gl-text-gray-800">
        {{ $options.i18n.takeNextLevel.description }}
      </p>
    </div>

    <div class="gl-display-flex gl-w-full gl-flex-flow-row-wrap">
      <card-showcase
        :title="$options.i18n.vulnerability_management.title"
        :description="$options.i18n.vulnerability_management.description"
        :primary-action="$options.i18n.vulnerability_management.primaryAction"
        :primary-link="trialVulnerabilityManagement"
        primary-tracking-label="start_trial"
        primary-tracking-property="vulnerability_management"
        :secondary-action="$options.i18n.vulnerability_management.secondaryAction"
        :secondary-link="billingVulnerabilityManagement"
        secondary-tracking-label="upgrade_now"
        secondary-tracking-property="vulnerability_management"
      />
      <card-showcase
        :title="$options.i18n.dependency_scanning.title"
        :description="$options.i18n.dependency_scanning.description"
        :primary-action="$options.i18n.dependency_scanning.primaryAction"
        :primary-link="trialDependencyScanning"
        primary-tracking-label="start_trial"
        primary-tracking-property="dependency_scanning"
        :secondary-action="$options.i18n.dependency_scanning.secondaryAction"
        :secondary-link="billingDependencyScanning"
        secondary-tracking-label="upgrade_now"
        secondary-tracking-property="dependency_scanning"
      />
      <card-showcase
        :title="$options.i18n.dast.title"
        :description="$options.i18n.dast.description"
        :primary-action="$options.i18n.dast.primaryAction"
        :primary-link="trialDast"
        primary-tracking-label="start_trial"
        primary-tracking-property="dast"
        :secondary-action="$options.i18n.dast.secondaryAction"
        :secondary-link="billingDast"
        secondary-tracking-label="upgrade_now"
        secondary-tracking-property="dast"
      />
      <card-showcase
        :title="$options.i18n.container_scanning.title"
        :description="$options.i18n.container_scanning.description"
        :primary-action="$options.i18n.container_scanning.primaryAction"
        :primary-link="trialContainerScanning"
        primary-tracking-label="start_trial"
        primary-tracking-property="container_scanning"
        :secondary-action="$options.i18n.container_scanning.secondaryAction"
        :secondary-link="billingContainerScanning"
        secondary-tracking-label="upgrade_now"
        secondary-tracking-property="container_scanning"
      />
    </div>
  </div>
</template>
