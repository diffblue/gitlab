<script>
import CEWidgetApp from '~/vue_merge_request_widget/components/widget/app.vue';

export default {
  components: {
    MrSecurityWidget: () =>
      import(
        'ee/vue_merge_request_widget/extensions/security_reports/mr_widget_security_reports.vue'
      ),
  },

  extends: CEWidgetApp,

  computed: {
    widgets() {
      return [window.gon?.features?.refactorSecurityExtension && 'MrSecurityWidget'].filter(
        (w) => w,
      );
    },
  },

  render: CEWidgetApp.render,
};
</script>
