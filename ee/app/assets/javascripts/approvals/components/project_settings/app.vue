<script>
import App from '../app.vue';
import ScanResultPolicies from '../security_orchestration/scan_result_policies.vue';
import ProjectApprovalSettings from './project_approval_settings.vue';
import ProjectRules from './project_rules.vue';

export default {
  components: {
    App,
    ProjectApprovalSettings,
    ProjectRules,
    ScanResultPolicies,
  },
};
</script>

<template>
  <div>
    <app :is-mr-edit="false">
      <template #rules>
        <project-rules />
      </template>
    </app>
    <scan-result-policies class="gl-mt-5" />
    <project-approval-settings class="gl-mt-5" />
  </div>
</template>
