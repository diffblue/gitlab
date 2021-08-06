<script>
import App from '../app.vue';
import ProjectApprovalSettings from './project_approval_settings.vue';
import ProjectRules from './project_rules.vue';

export default {
  components: {
    App,
    ProjectApprovalSettings,
    ProjectRules,
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
    <project-approval-settings class="gl-mt-5" />
  </div>
</template>
