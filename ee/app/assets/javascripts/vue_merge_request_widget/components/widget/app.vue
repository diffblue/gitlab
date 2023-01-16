<script>
import CEWidgetApp from '~/vue_merge_request_widget/components/widget/app.vue';

export default {
  components: {
    MrSecurityWidgetEE: () =>
      import(
        'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
    MrSecurityWidgetCE: () =>
      import(
        '~/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
  },

  extends: CEWidgetApp,

  securityReportTypes: [
    'dast',
    'sast',
    'dependencyScanning',
    'containerScanning',
    'coverageFuzzing',
    'apiFuzzing',
    'secretDetection',
  ],

  computed: {
    securityReportsWidget() {
      const { enabledReports } = this.mr;

      if (!window.gon?.features?.refactorSecurityExtension) {
        return false;
      }

      return enabledReports &&
        this.mr.canReadVulnerabilities &&
        this.$options.securityReportTypes.some((reportType) => enabledReports[reportType])
        ? 'MrSecurityWidgetEE'
        : 'MrSecurityWidgetCE';
    },

    widgets() {
      return [this.securityReportsWidget].filter((w) => w);
    },
  },

  render: CEWidgetApp.render,
};
</script>
