<script>
import { GlAlert, GlSprintf, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import ScanNewPolicyModal from './scan_new_policy_modal.vue';

export default {
  components: {
    GlSprintf,
    GlButton,
    GlAlert,
    ScanNewPolicyModal,
  },
  inject: [
    'assignedPolicyProject',
    'disableSecurityPolicyProject',
    'documentationPath',
    'newPolicyPath',
  ],
  i18n: {
    title: s__('SecurityOrchestration|Policies'),
    subtitle: s__(
      'SecurityOrchestration|Enforce security for this project. %{linkStart}More information.%{linkEnd}',
    ),
    newPolicyButtonText: s__('SecurityOrchestration|New policy'),
    editPolicyProjectButtonText: s__('SecurityOrchestration|Edit policy project'),
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
  },
  methods: {
    updateAlertText({ text, variant }) {
      this.projectIsBeingLinked = false;

      if (text) {
        this.showAlert = true;
        this.alertVariant = variant;
        this.alertText = text;
      }
      this.$emit('update-policy-list', true);
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
      <gl-button data-testid="new-policy-button" variant="confirm" :href="newPolicyPath">
        {{ $options.i18n.newPolicyButtonText }}
      </gl-button>
      <scan-new-policy-modal
        :visible="modalVisible"
        @close="modalVisible = false"
        @project-updated="updateAlertText"
        @updating-project="isUpdatingProject"
      />
    </header>
  </div>
</template>
