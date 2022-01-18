<script>
import { GlBanner } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlBanner,
  },
  inject: ['securityConfigurationPath'],
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
};
</script>

<template>
  <gl-banner
    :title="$options.i18n.title"
    :button-text="$options.i18n.buttonText"
    :button-link="buttonLink"
    variant="introduction"
  >
    <p>{{ $options.i18n.content }}</p>
  </gl-banner>
</template>
