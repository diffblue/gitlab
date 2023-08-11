<script>
import CEWidgetApp from '~/vue_merge_request_widget/components/widget/app.vue';

export default {
  components: {
    MrMetricsWidget: () => import('ee/vue_merge_request_widget/extensions/metrics/index.vue'),
    MrSecurityWidgetEE: () =>
      import(
        'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrSecurityWidgetCE: () =>
      import(
        '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrStatusChecksWidget: () =>
      import('ee/vue_merge_request_widget/extensions/status_checks/index.vue'),
  },

  extends: CEWidgetApp,

  computed: {
    metricsWidget() {
      return this.mr.metricsReportsPath ? 'MrMetricsWidget' : undefined;
    },

    statusChecksWidget() {
      return this.mr.apiStatusChecksPath && !this.mr.isNothingToMergeState
        ? 'MrStatusChecksWidget'
        : undefined;
    },

    securityReportsWidget() {
      return this.mr.canReadVulnerabilities ? 'MrSecurityWidgetEE' : 'MrSecurityWidgetCE';
    },

    widgets() {
      return [
        this.codeQualityWidget,
        this.metricsWidget,
        this.statusChecksWidget,
        this.terraformPlansWidget,
        this.securityReportsWidget,
      ].filter((w) => w);
    },
  },

  render: CEWidgetApp.render,
};
</script>
