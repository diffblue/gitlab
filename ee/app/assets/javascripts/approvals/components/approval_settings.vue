<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { sprintf } from '~/locale';
import { APPROVAL_SETTINGS_I18N, TYPE_GROUP } from '../constants';
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
      settings: (state) => state.approvalSettings.settings,
      errorMessage: (state) => state.approvalSettings.errorMessage,
      preventAuthorApproval: (state) => state.approvalSettings.settings.preventAuthorApproval,
      preventCommittersApproval: (state) =>
        state.approvalSettings.settings.preventCommittersApproval,
      preventMrApprovalRuleEdit: (state) =>
        state.approvalSettings.settings.preventMrApprovalRuleEdit,
      removeApprovalsOnPush: (state) => state.approvalSettings.settings.removeApprovalsOnPush,
      requireUserPassword: (state) => state.approvalSettings.settings.requireUserPassword,
      groupName: (state) => state.settings.groupName,
    }),
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
      'setPreventAuthorApproval',
      'setPreventCommittersApproval',
      'setPreventMrApprovalRuleEdit',
      'setRemoveApprovalsOnPush',
      'setRequireUserPassword',
    ]),
    async onSubmit() {
      await this.updateSettings(this.approvalSettingsPath);
      this.$toast.show(APPROVAL_SETTINGS_I18N.savingSuccessMessage);
    },
    lockedText({ locked, inheritedFrom }) {
      if (!locked) {
        return null;
      }
      if (inheritedFrom === TYPE_GROUP) {
        const { groupName } = this;
        return sprintf(APPROVAL_SETTINGS_I18N.lockedByGroupOwner, { groupName });
      }
      return APPROVAL_SETTINGS_I18N.lockedByAdmin;
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
      :class="{ 'gl-mb-6': hasSettings }"
      data-testid="error-alert"
      @dismiss="dismissErrorMessage"
    >
      {{ errorMessage }}
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
          :checked="preventAuthorApproval.value"
          :label="settingsLabels.authorApprovalLabel"
          :locked="!canPreventAuthorApproval || preventAuthorApproval.locked"
          :locked-text="lockedText(preventAuthorApproval)"
          data-testid="prevent-author-approval"
          @input="setPreventAuthorApproval"
        />
        <approval-settings-checkbox
          :checked="preventCommittersApproval.value"
          :label="settingsLabels.preventCommittersApprovalLabel"
          :locked="!canPreventCommittersApproval || preventCommittersApproval.locked"
          :locked-text="lockedText(preventCommittersApproval)"
          data-testid="prevent-committers-approval"
          @input="setPreventCommittersApproval"
        />
        <approval-settings-checkbox
          :checked="preventMrApprovalRuleEdit.value"
          :label="settingsLabels.preventMrApprovalRuleEditLabel"
          :locked="!canPreventMrApprovalRuleEdit || preventMrApprovalRuleEdit.locked"
          :locked-text="lockedText(preventMrApprovalRuleEdit)"
          data-testid="prevent-mr-approval-rule-edit"
          @input="setPreventMrApprovalRuleEdit"
        />
        <approval-settings-checkbox
          :checked="requireUserPassword.value"
          :label="settingsLabels.requireUserPasswordLabel"
          :locked="requireUserPassword.locked"
          :locked-text="lockedText(requireUserPassword)"
          data-testid="require-user-password"
          @input="setRequireUserPassword"
        />
        <approval-settings-checkbox
          :checked="removeApprovalsOnPush.value"
          :label="settingsLabels.removeApprovalsOnPushLabel"
          :locked="removeApprovalsOnPush.locked"
          :locked-text="lockedText(removeApprovalsOnPush)"
          data-testid="remove-approvals-on-push"
          @input="setRemoveApprovalsOnPush"
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
