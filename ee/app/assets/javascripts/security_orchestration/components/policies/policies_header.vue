<script>
import { GlAlert, GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { NEW_POLICY_BUTTON_TEXT } from '../constants';
import PolicyProjectModal from './policy_project_modal.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlSprintf,
    PolicyProjectModal,
  },
  inject: [
    'assignedPolicyProject',
    'disableSecurityPolicyProject',
    'disableScanPolicyUpdate',
    'documentationPath',
    'newPolicyPath',
  ],
  i18n: {
    title: s__('SecurityOrchestration|Policies'),
    subtitle: s__(
      'SecurityOrchestration|Enforce security for this project. %{linkStart}More information.%{linkEnd}',
    ),
    newPolicyButtonText: NEW_POLICY_BUTTON_TEXT,
    editPolicyProjectButtonText: s__('SecurityOrchestration|Edit policy project'),
    viewPolicyProjectButtonText: s__('SecurityOrchestration|View policy project'),
  },
  data() {
    return {
      projectIsBeingLinked: false,
      showAlert: false,
      alertVariant: '',
      alertText: '',
      modalVisible: false,
    };
  },
  computed: {
    hasAssignedPolicyProject() {
      return Boolean(this.assignedPolicyProject?.id);
    },
    securityPolicyProjectPath() {
      return joinPaths('/', this.assignedPolicyProject?.full_path);
    },
  },
  methods: {
    updateAlertText({ text, variant, hasPolicyProject }) {
      this.projectIsBeingLinked = false;

      if (text) {
        this.showAlert = true;
        this.alertVariant = variant;
        this.alertText = text;
      }
      this.$emit('update-policy-list', { hasPolicyProject, shouldUpdatePolicyList: true });
    },
    isUpdatingProject() {
      this.projectIsBeingLinked = true;
      this.showAlert = false;
      this.alertVariant = '';
      this.alertText = '';
    },
    dismissAlert() {
      this.showAlert = false;
    },
    showNewPolicyModal() {
      this.modalVisible = true;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showAlert"
      class="gl-mt-3"
      data-testid="policy-project-alert"
      :dismissible="true"
      :variant="alertVariant"
      @dismiss="dismissAlert"
    >
      {{ alertText }}
    </gl-alert>
    <header class="gl-my-6 gl-display-flex gl-align-items-flex-start">
      <div class="gl-flex-grow-1 gl-my-0">
        <h2 class="gl-mt-0">
          {{ $options.i18n.title }}
        </h2>
        <p data-testid="policies-subheader">
          <gl-sprintf :message="$options.i18n.subtitle">
            <template #link="{ content }">
              <gl-button class="gl-pb-1!" variant="link" :href="documentationPath" target="_blank">
                {{ content }}
              </gl-button>
            </template>
          </gl-sprintf>
        </p>
      </div>
      <gl-button
        v-if="!disableSecurityPolicyProject"
        data-testid="edit-project-policy-button"
        class="gl-mr-4"
        :loading="projectIsBeingLinked"
        @click="showNewPolicyModal"
      >
        {{ $options.i18n.editPolicyProjectButtonText }}
      </gl-button>
      <gl-button
        v-else-if="hasAssignedPolicyProject"
        data-testid="view-project-policy-button"
        class="gl-mr-3"
        target="_blank"
        :href="securityPolicyProjectPath"
      >
        <gl-icon name="external-link" />
        {{ $options.i18n.viewPolicyProjectButtonText }}
      </gl-button>
      <gl-button
        v-if="!disableScanPolicyUpdate"
        data-testid="new-policy-button"
        data-qa-selector="new_policy_button"
        variant="confirm"
        :href="newPolicyPath"
      >
        {{ $options.i18n.newPolicyButtonText }}
      </gl-button>
      <policy-project-modal
        :visible="modalVisible"
        @close="modalVisible = false"
        @project-updated="updateAlertText"
        @updating-project="isUpdatingProject"
      />
    </header>
  </div>
</template>
