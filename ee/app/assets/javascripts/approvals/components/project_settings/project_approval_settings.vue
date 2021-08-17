<script>
import { mapState } from 'vuex';
import { __ } from '~/locale';
import { PROJECT_APPROVAL_SETTINGS_LABELS_I18N } from '../../constants';
import ApprovalSettings from '../approval_settings.vue';

export default {
  components: {
    ApprovalSettings,
  },
  computed: {
    ...mapState({
      approvalsPath: (state) => state.settings.approvalsPath,
      canPreventMrApprovalRuleEdit: (state) => state.settings.canEdit,
      canModifyAuthorSettings: (state) => state.settings.canModifyAuthorSettings,
      canModifyCommiterSettings: (state) => state.settings.canModifyCommiterSettings,
    }),
  },
  i18n: {
    projectSettingsHeader: __('Approval settings'),
  },
  labels: PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
};
</script>

<template>
  <div data-testid="merge-request-approval-settings">
    <label class="label-bold">
      {{ $options.i18n.projectSettingsHeader }}
    </label>
    <approval-settings
      :approval-settings-path="approvalsPath"
      :can-prevent-author-approval="canModifyAuthorSettings"
      :can-prevent-committers-approval="canModifyCommiterSettings"
      :can-prevent-mr-approval-rule-edit="canPreventMrApprovalRuleEdit"
      :settings-labels="$options.labels"
    />
  </div>
</template>
