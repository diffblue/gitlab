<script>
import { s__ } from '~/locale';

export default {
  name: 'ProductAnalyticsOnboardingView',
  i18n: {
    content: s__('Product Analytics|Onboarding view'),
  },
};
</script>

<template>
  <p>{{ $options.i18n.content }}</p>
</template>
