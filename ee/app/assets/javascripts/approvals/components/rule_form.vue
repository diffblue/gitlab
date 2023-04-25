<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { groupBy, isEqual, isNumber } from 'lodash';
import { mapState, mapActions } from 'vuex';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import { sprintf } from '~/locale';
import {
  ALL_BRANCHES,
  ALL_PROTECTED_BRANCHES,
} from 'ee/vue_shared/components/branches_selector/constants';
import {
  TYPE_USER,
  TYPE_GROUP,
  TYPE_HIDDEN_GROUPS,
  COVERAGE_CHECK_NAME,
  APPROVAL_DIALOG_I18N,
} from '../constants';
import ApproversList from './approvers_list.vue';
import ApproversSelect from './approvers_select.vue';

const DEFAULT_NAME = 'Default';

export const READONLY_NAMES = [COVERAGE_CHECK_NAME];

function mapServerResponseToValidationErrors(messages) {
  return Object.entries(messages).flatMap(([key, msgs]) => msgs.map((msg) => `${key} ${msg}`));
}

export default {
  components: {
    ApproversList,
    ApproversSelect,
    GlFormGroup,
    GlFormInput,
    ProtectedBranchesSelector,
  },
  props: {
    initRule: {
      type: Object,
      required: false,
      default: null,
    },
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
    defaultRuleName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      name: this.defaultRuleName,
      approvalsRequired: 1,
      vulnerabilitiesAllowed: 0,
      minApprovalsRequired: 0,
      approvers: [],
      approversToAdd: [],
      branches: [],
      branchesToAdd: [],
      showValidation: false,
      isFallback: false,
      containsHiddenGroups: false,
      serverValidationErrors: [],
      ...this.getInitialData(),
    };
  },
  computed: {
    ...mapState(['settings']),
    rule() {
      // If we are creating a new rule with a suggested approval name
      return this.defaultRuleName ? null : this.initRule;
    },
    approversByType() {
      return groupBy(this.approvers, (x) => x.type);
    },
    users() {
      return this.approversByType[TYPE_USER] || [];
    },
    groups() {
      return this.approversByType[TYPE_GROUP] || [];
    },
    userIds() {
      return this.users.map((x) => x.id);
    },
    skipUserIds() {
      const skipAuthorId = this.isMrEdit && this.settings.authorId ? [this.settings.authorId] : [];
      return [...this.userIds, ...skipAuthorId];
    },
    groupIds() {
      return this.groups.map((x) => x.id);
    },
    invalidName() {
      if (this.isMultiSubmission) {
        if (this.serverValidationErrors.includes('name has already been taken')) {
          return APPROVAL_DIALOG_I18N.validations.ruleNameTaken;
        }

        if (!this.name) {
          return APPROVAL_DIALOG_I18N.validations.ruleNameMissing;
        }
      }

      return '';
    },
    invalidApprovalsRequired() {
      if (!isNumber(this.approvalsRequired)) {
        return APPROVAL_DIALOG_I18N.validations.approvalsRequiredNotNumber;
      }

      if (this.approvalsRequired < 0) {
        return APPROVAL_DIALOG_I18N.validations.approvalsRequiredNegativeNumber;
      }

      if (this.approvalsRequired < this.minApprovalsRequired) {
        return sprintf(APPROVAL_DIALOG_I18N.validations.approvalsRequiredMinimum, {
          number: this.minApprovalsRequired,
        });
      }

      return '';
    },
    invalidApprovers() {
      if (this.isMultiSubmission && this.approvers.length <= 0) {
        return APPROVAL_DIALOG_I18N.validations.approversRequired;
      }

      return '';
    },
    invalidBranches() {
      if (
        !this.isMrEdit &&
        !this.branches.every(
          (branch) =>
            isEqual(branch, ALL_BRANCHES) ||
            isEqual(branch, ALL_PROTECTED_BRANCHES) ||
            isNumber(branch?.id),
        )
      ) {
        return APPROVAL_DIALOG_I18N.validations.branchesRequired;
      }

      return '';
    },
    isValid() {
      return (
        this.isValidName &&
        this.isValidBranches &&
        this.isValidApprovalsRequired &&
        this.isValidApprovers
      );
    },
    isValidName() {
      return !this.showValidation || !this.invalidName;
    },
    isValidBranches() {
      return !this.showValidation || !this.invalidBranches;
    },
    isValidApprovalsRequired() {
      return !this.showValidation || !this.invalidApprovalsRequired;
    },
    isValidApprovers() {
      return !this.showValidation || !this.invalidApprovers;
    },
    isMultiSubmission() {
      return this.settings.allowMultiRule && !this.isFallbackSubmission;
    },
    isFallbackSubmission() {
      return (
        this.settings.allowMultiRule && this.isFallback && !this.name && !this.approvers.length
      );
    },
    isPersisted() {
      return this.initRule && this.initRule.id;
    },
    showName() {
      return !this.settings.lockedApprovalsRuleName;
    },
    isNameDisabled() {
      return (
        Boolean(this.isPersisted || this.defaultRuleName) && READONLY_NAMES.includes(this.name)
      );
    },
    showProtectedBranch() {
      return !this.isMrEdit && this.settings.allowMultiRule;
    },
    removeHiddenGroups() {
      return this.containsHiddenGroups && !this.approversByType[TYPE_HIDDEN_GROUPS];
    },
    submissionData() {
      const appliesToAllProtectedBranches = this.branches.some(
        (x) => x.id === ALL_PROTECTED_BRANCHES.id,
      );
      const protectedBranchIds = this.branches
        .map((x) => x.id)
        .filter((x) => x !== ALL_BRANCHES.id && x !== ALL_PROTECTED_BRANCHES.id);

      return {
        id: this.initRule && this.initRule.id,
        name: this.settings.lockedApprovalsRuleName || this.name || DEFAULT_NAME,
        appliesToAllProtectedBranches,
        approvalsRequired: this.approvalsRequired,
        users: this.userIds,
        groups: this.groupIds,
        userRecords: this.users,
        groupRecords: this.groups,
        removeHiddenGroups: this.removeHiddenGroups,
        protectedBranchIds,
      };
    },
    isEditing() {
      return Boolean(this.initRule);
    },
  },
  watch: {
    approversToAdd(value) {
      this.approvers.push(value[0]);
    },
    branchesToAdd(value) {
      this.branches = value ? [value] : [];
    },
  },
  methods: {
    ...mapActions(['putFallbackRule', 'postRule', 'putRule', 'deleteRule', 'postRegularRule']),
    addSelection() {
      if (!this.approversToAdd.length) {
        return;
      }

      this.approvers = this.approversToAdd.concat(this.approvers);
      this.approversToAdd = [];
    },
    /**
     * Validate and submit the form based on what type it is.
     * - Fallback rule?
     * - Single rule?
     * - Multi rule?
     */
    async submit() {
      let submission;

      this.serverValidationErrors = [];
      this.showValidation = true;

      if (!this.isValid) {
        submission = Promise.resolve;
      } else if (this.isFallbackSubmission) {
        submission = this.submitFallback;
      } else if (!this.isMultiSubmission) {
        submission = this.submitSingleRule;
      } else {
        submission = this.submitRule;
      }

      try {
        await submission();
      } catch (failureResponse) {
        this.serverValidationErrors = mapServerResponseToValidationErrors(
          failureResponse?.response?.data?.message || {},
        );
      }
    },
    /**
     * Submit the rule, by either put-ing or post-ing.
     */
    submitRule() {
      const data = this.submissionData;

      if (!this.settings.allowMultiRule && this.settings.prefix === 'mr-edit') {
        return data.id ? this.putRule(data) : this.postRegularRule(data);
      }

      return data.id ? this.putRule(data) : this.postRule(data);
    },
    /**
     * Submit as a fallback rule.
     */
    submitFallback() {
      return this.putFallbackRule({ approvalsRequired: this.approvalsRequired });
    },
    /**
     * Submit as a single rule. This is determined by the settings.
     */
    submitSingleRule() {
      if (!this.approvers.length) {
        return this.submitEmptySingleRule();
      }

      return this.submitRule();
    },
    /**
     * Submit as a single rule without approvers, so submit the fallback.
     * Also delete the rule if necessary.
     */
    submitEmptySingleRule() {
      const id = this.initRule && this.initRule.id;

      return Promise.all([this.submitFallback(), id ? this.deleteRule(id) : Promise.resolve()]);
    },
    getInitialData() {
      if (!this.initRule || this.defaultRuleName) {
        return {};
      }

      if (this.initRule.isFallback) {
        return {
          approvalsRequired: this.initRule.approvalsRequired,
          isFallback: this.initRule.isFallback,
        };
      }

      const { containsHiddenGroups = false, removeHiddenGroups = false } = this.initRule;

      const users = this.initRule.users.map((x) => ({ ...x, type: TYPE_USER }));
      const groups = this.initRule.groups.map((x) => ({ ...x, type: TYPE_GROUP }));
      const branches = [];

      if (this.initRule.appliesToAllProtectedBranches) {
        branches.push(ALL_PROTECTED_BRANCHES);
      } else if (this.initRule.protectedBranches?.length > 0) {
        branches.push(...this.initRule.protectedBranches);
      }

      if (!branches.length) {
        branches.push(ALL_BRANCHES);
      }

      return {
        name: this.initRule.name || '',
        approvalsRequired: this.initRule.approvalsRequired || 0,
        minApprovalsRequired: this.initRule.minApprovalsRequired || 0,
        containsHiddenGroups,
        approvers: groups
          .concat(users)
          .concat(
            containsHiddenGroups && !removeHiddenGroups ? [{ type: TYPE_HIDDEN_GROUPS }] : [],
          ),
        branches,
      };
    },
  },
  APPROVAL_DIALOG_I18N,
  ruleNameInput: 'rule-name-input',
  approvalsRequiredInput: 'approvals-required-input',
};
</script>

<template>
  <form novalidate @submit.prevent.stop="submit">
    <gl-form-group
      v-if="showName"
      :label="$options.APPROVAL_DIALOG_I18N.form.nameLabel"
      :label-for="$options.ruleNameInput"
      :description="$options.APPROVAL_DIALOG_I18N.form.nameDescription"
      :state="isValidName"
      :invalid-feedback="invalidName"
      data-testid="name-group"
    >
      <gl-form-input
        :id="$options.ruleNameInput"
        v-model="name"
        :disabled="isNameDisabled"
        :state="isValidName"
        data-qa-selector="rule_name_field"
        data-testid="name"
      />
    </gl-form-group>
    <gl-form-group
      v-if="showProtectedBranch"
      :label="$options.APPROVAL_DIALOG_I18N.form.protectedBranchLabel"
      :description="$options.APPROVAL_DIALOG_I18N.form.protectedBranchDescription"
      :state="isValidBranches"
      :invalid-feedback="invalidBranches"
      data-testid="branches-group"
    >
      <protected-branches-selector
        v-model="branchesToAdd"
        :project-id="settings.projectId"
        :is-invalid="!isValidBranches"
        :allow-all-protected-branches-option="settings.allowAllProtectedBranchesOption"
        :selected-branches="branches"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.APPROVAL_DIALOG_I18N.form.approvalsRequiredLabel"
      :label-for="$options.approvalsRequiredInput"
      :state="isValidApprovalsRequired"
      :invalid-feedback="invalidApprovalsRequired"
      data-testid="approvals-required-group"
    >
      <gl-form-input
        :id="$options.approvalsRequiredInput"
        v-model.number="approvalsRequired"
        :state="isValidApprovalsRequired"
        :min="minApprovalsRequired"
        class="mw-6em"
        type="number"
        data-testid="approvals-required"
        data-qa-selector="approvals_required_field"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.APPROVAL_DIALOG_I18N.form.approversLabel"
      :state="isValidApprovers"
      :invalid-feedback="invalidApprovers"
      data-testid="approvers-group"
      data-qa-selector="member_select_field"
    >
      <approvers-select
        v-model="approversToAdd"
        :namespace-id="settings.projectId"
        :skip-user-ids="skipUserIds"
        :skip-group-ids="groupIds"
        :is-invalid="!isValidApprovers"
      />
    </gl-form-group>
    <div class="bordered-box overflow-auto h-12em">
      <approvers-list v-model="approvers" />
    </div>
  </form>
</template>
