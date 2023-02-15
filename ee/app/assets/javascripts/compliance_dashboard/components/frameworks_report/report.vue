<script>
import UrlSync from '~/vue_shared/components/url_sync.vue';
import { buildDefaultFrameworkFilterParams } from 'ee/compliance_dashboard/utils';

export default {
  name: 'ComplianceFrameworkReport',
  components: {
    UrlSync,
  },
  data() {
    const urlQuery = buildDefaultFrameworkFilterParams(window.location.search);
    return {
      urlQuery,
    };
  },
};
</script>

<template>
  <div id="compliance-framework-report">
    <!-- Disable the "compliance_frameworks_report" feature flag to hide this. -->
    <url-sync :query="urlQuery" url-params-update-strategy="set" />
  </div>
</template>
