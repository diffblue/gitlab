<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { mapComputed } from '~/vuex_shared/bindings';
import { APPROVAL_SETTINGS_I18N } from '../constants';
import ApprovalSettingsCheckbox from './approval_settings_checkbox.vue';

export default {
  components: {
    ApprovalSettingsCheckbox,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlLoadingIcon,
    GlLink,
  },
  props: {
    approvalSettingsPath: {
      type: String,
      required: true,
    },
    settingsLabels: {
      type: Object,
      required: true,
    },
    canPreventMrApprovalRuleEdit: {
      type: Boolean,
      required: false,
      default: true,
    },
    canPreventAuthorApproval: {
      type: Boolean,
      required: false,
      default: true,
    },
    canPreventCommittersApproval: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState({
      isLoading: (state) => state.approvalSettings.isLoading,
      isUpdated: (state) => state.approvalSettings.isUpdated,
      settings: (state) => state.approvalSettings.settings,
      errorMessage: (state) => state.approvalSettings.errorMessage,
    }),
    ...mapComputed(
      [
        { key: 'preventAuthorApproval', updateFn: 'setPreventAuthorApproval' },
        { key: 'preventCommittersApproval', updateFn: 'setPreventCommittersApproval' },
        { key: 'preventMrApprovalRuleEdit', updateFn: 'setPreventMrApprovalRuleEdit' },
        { key: 'removeApprovalsOnPush', updateFn: 'setRemoveApprovalsOnPush' },
        { key: 'requireUserPassword', updateFn: 'setRequireUserPassword' },
      ],
      undefined,
      (state) => state.approvalSettings.settings,
    ),
    ...mapGetters(['settingChanged']),
    hasSettings() {
      return !isEmpty(this.settings);
    },
    isLoaded() {
      return this.hasSettings || this.errorMessage;
    },
  },
  created() {
    this.fetchSettings(this.approvalSettingsPath);
  },
  methods: {
    ...mapActions([
      'fetchSettings',
      'updateSettings',
      'dismissErrorMessage',
      'dismissSuccessMessage',
    ]),
    async onSubmit() {
      await this.updateSettings(this.approvalSettingsPath);
    },
  },
  i18n: APPROVAL_SETTINGS_I18N,
  links: {
    approvalSettingsDocsPath: helpPagePath('user/project/merge_requests/approvals/settings'),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="!isLoaded" size="lg" />
    <gl-alert
      v-if="errorMessage"
      variant="danger"
      :dismissible="hasSettings"
      :contained="true"
      :class="{ 'gl-mb-6': hasSettings }"
      data-testid="error-alert"
      @dismiss="dismissErrorMessage"
    >
      {{ errorMessage }}
    </gl-alert>
    <gl-alert
      v-if="isUpdated"
      variant="success"
      :dismissible="true"
      :contained="true"
      class="gl-mb-6"
      data-testid="success-alert"
      @dismiss="dismissSuccessMessage"
    >
      {{ $options.i18n.savingSuccessMessage }}
    </gl-alert>
    <gl-form v-if="hasSettings" @submit.prevent="onSubmit">
      <label class="label-bold"> {{ $options.i18n.approvalSettingsHeader }} </label>
      <p>
        {{ $options.i18n.approvalSettingsDescription }}
        <gl-link :href="$options.links.approvalSettingsDocsPath" target="_blank">
          {{ $options.i18n.learnMore }}
        </gl-link>
      </p>
      <gl-form-group>
        <approval-settings-checkbox
          v-model="preventAuthorApproval"
          :label="settingsLabels.authorApprovalLabel"
          :locked="!canPreventAuthorApproval"
          :locked-text="$options.i18n.lockedByAdmin"
          data-testid="prevent-author-approval"
        />
        <approval-settings-checkbox
          v-model="preventCommittersApproval"
          :label="settingsLabels.preventCommittersApprovalLabel"
          :locked="!canPreventCommittersApproval"
          :locked-text="$options.i18n.lockedByAdmin"
          data-testid="prevent-committers-approval"
        />
        <approval-settings-checkbox
          v-model="preventMrApprovalRuleEdit"
          :label="settingsLabels.preventMrApprovalRuleEditLabel"
          :locked="!canPreventMrApprovalRuleEdit"
          :locked-text="$options.i18n.lockedByAdmin"
          data-testid="prevent-mr-approval-rule-edit"
        />
        <approval-settings-checkbox
          v-model="requireUserPassword"
          :label="settingsLabels.requireUserPasswordLabel"
          data-testid="require-user-password"
        />
        <approval-settings-checkbox
          v-model="removeApprovalsOnPush"
          :label="settingsLabels.removeApprovalsOnPushLabel"
          data-testid="remove-approvals-on-push"
        />
      </gl-form-group>
      <gl-button
        type="submit"
        variant="confirm"
        category="primary"
        :disabled="!settingChanged"
        :loading="isLoading"
      >
        {{ $options.i18n.saveChanges }}
      </gl-button>
    </gl-form>
  </div>
</template>
