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

  computed: {
    securityReportsWidget() {
      return this.mr.canReadVulnerabilities ? 'MrSecurityWidgetEE' : 'MrSecurityWidgetCE';
    },

    widgets() {
      return [this.terraformPlansWidget, this.securityReportsWidget].filter((w) => w);
    },
  },

  render: CEWidgetApp.render,
};
</script>
