<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOC_PATH_VULNERABILITY_DETAILS } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inject: {
    canViewFalsePositive: {
      default: false,
    },
  },
  i18n: {
    title: s__('Vulnerability|False positive detected'),
    message: s__(
      'Vulnerability|The scanner determined this vulnerability to be a false positive. Verify the evaluation before changing its status. %{linkStart}Learn more about false positive detection.%{linkEnd}',
    ),
  },
  DOC_PATH_VULNERABILITY_DETAILS,
};
</script>

<template>
  <gl-alert
    v-if="canViewFalsePositive"
    :title="$options.i18n.title"
    :dismissible="false"
    variant="warning"
    data-qa-selector="false_positive_alert"
  >
    <gl-sprintf :message="$options.i18n.message">
      <template #link="{ content }">
        <gl-link
          class="gl-font-sm!"
          :href="$options.DOC_PATH_VULNERABILITY_DETAILS"
          target="_blank"
        >
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
