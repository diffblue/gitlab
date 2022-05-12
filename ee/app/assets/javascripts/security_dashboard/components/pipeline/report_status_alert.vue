<script>
import { GlAlert, GlSprintf, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD } from 'ee/security_dashboard/constants';

export const STATUS_PURGED = 'PURGED';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlButton,
  },
  i18n: {
    reportStatusTitle: s__('SecurityReports|Report has expired'),
    reportExpiredMessage: s__(
      `SecurityReports|The security report for this pipeline has %{helpPageLinkStart}expired%{helpPageLinkEnd}. Re-run the pipeline to generate a new security report.`,
    ),
  },
  DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD,
};
</script>

<template>
  <gl-alert variant="info" :dismissible="false">
    <strong role="heading">{{ $options.i18n.reportStatusTitle }}</strong>
    <p class="gl-mt-3">
      <gl-sprintf :message="$options.i18n.reportExpiredMessage" data-testid="description">
        <template #helpPageLink="{ content }">
          <gl-button
            variant="link"
            icon="external-link"
            :href="$options.DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD"
            target="_blank"
          >
            {{ content }}
          </gl-button>
        </template>
      </gl-sprintf>
    </p>
  </gl-alert>
</template>
