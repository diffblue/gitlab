<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { uniqueId, orderBy } from 'lodash';
import ApprovalCheckRulePopover from 'ee/approvals/components/approval_check_rule_popover.vue';
import EmptyRuleName from 'ee/approvals/components/empty_rule_name.vue';
import { RULE_TYPE_CODE_OWNER, RULE_TYPE_ANY_APPROVER } from 'ee/approvals/constants';
import { sprintf, __, s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ApprovedIcon from './approved_icon.vue';
import NumberOfApprovals from './number_of_approvals.vue';
import approvalRulesQuery from './queries/approval_rules.query.graphql';

const INCLUDE_APPROVERS = 1;
const DO_NOT_INCLUDE_APPROVERS = 2;

export default {
  apollo: {
    mergeRequest: {
      query: approvalRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          iid: this.iid,
        };
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  components: {
    GlSkeletonLoader,
    UserAvatarList,
    ApprovedIcon,
    ApprovalCheckRulePopover,
    EmptyRuleName,
    NumberOfApprovals,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    codeCoverageCheckHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      mergeRequest: {},
    };
  },
  computed: {
    sections() {
      const approvalRules = this.mergeRequest.approvalState.rules;

      return [
        {
          id: uniqueId(),
          title: '',
          rules: approvalRules.filter((rule) => rule.type.toLowerCase() !== RULE_TYPE_CODE_OWNER),
        },
        {
          id: uniqueId(),
          title: __('Code Owners'),
          rules: orderBy(
            approvalRules
              .filter((rule) => rule.type.toLowerCase() === RULE_TYPE_CODE_OWNER)
              .map((rule) => ({ ...rule, nameClass: 'gl-font-monospace gl-word-break-all' })),
            [(o) => o.section === 'codeowners', 'name', 'section'],
            ['desc', 'asc', 'asc'],
          ),
        },
      ].filter((x) => x.rules.length);
    },
  },
  methods: {
    summaryText(rule) {
      return rule.approvalsRequired === 0
        ? this.summaryOptionalText(rule)
        : this.summaryRequiredText(rule);
    },
    summaryRequiredText(rule) {
      return sprintf(__('%{count} of %{required} approvals from %{name}'), {
        count: rule.approvedBy.nodes.length,
        required: rule.approvalsRequired,
        name: rule.name,
      });
    },
    summaryOptionalText(rule) {
      return sprintf(__('%{count} approvals from %{name}'), {
        count: rule.approvedBy.nodes.length,
        name: rule.name,
      });
    },
    sectionNameLabel(rule) {
      return sprintf(s__('Approvals|Section: %section'), { section: rule.section });
    },
    numberOfColumns(rule) {
      return rule.type.toLowerCase() === this.$options.ruleTypeAnyApprover
        ? DO_NOT_INCLUDE_APPROVERS
        : INCLUDE_APPROVERS;
    },
  },
  ruleTypeAnyApprover: RULE_TYPE_ANY_APPROVER,
};
</script>

<template>
  <table class="table m-0 gl-border-t">
    <thead class="thead-white text-nowrap">
      <tr class="d-md-table-row d-none gl-font-sm">
        <th class="gl-bg-white!"></th>
        <th class="gl-bg-white! gl-pl-0! gl-w-full">{{ s__('MRApprovals|Approvers') }}</th>
        <th class="gl-bg-white! gl-w-full"></th>
        <th class="gl-bg-white! gl-w-full">{{ s__('MRApprovals|Approvals') }}</th>
        <th class="gl-bg-white! gl-w-full">{{ s__('MRApprovals|Commented by') }}</th>
        <th class="gl-bg-white! gl-w-full">{{ s__('MRApprovals|Approved by') }}</th>
      </tr>
    </thead>
    <tbody v-if="$apollo.queries.mergeRequest.loading" class="border-top-0">
      <tr>
        <td></td>
        <td class="gl-pl-0!">
          <div class="gl-display-flex" style="width: 100px; height: 20px">
            <gl-skeleton-loader :width="100" :height="20">
              <rect width="100" height="20" x="0" y="0" rx="4" />
            </gl-skeleton-loader>
          </div>
        </td>
        <td></td>
        <td>
          <div class="gl-display-flex" style="width: 50px; height: 20px">
            <gl-skeleton-loader :width="50" :height="20">
              <rect width="50" height="20" x="0" y="0" rx="4" />
            </gl-skeleton-loader>
          </div>
        </td>
        <td>
          <div class="gl-display-flex" style="width: 20px; height: 20px">
            <gl-skeleton-loader :width="20" :height="20">
              <circle cx="10" cy="10" r="10" />
            </gl-skeleton-loader>
          </div>
        </td>
        <td>
          <div class="gl-display-flex" style="width: 20px; height: 20px">
            <gl-skeleton-loader :width="20" :height="20">
              <circle cx="10" cy="10" r="10" />
            </gl-skeleton-loader>
          </div>
        </td>
      </tr>
    </tbody>
    <template v-else>
      <tbody v-for="{ id, title, rules } in sections" :key="id" class="border-top-0">
        <tr v-if="title" class="js-section-title gl-bg-white">
          <td class="w-0"></td>
          <td colspan="99" class="gl-font-sm gl-text-gray-500 gl-pl-0!">
            <strong>{{ title }}</strong>
          </td>
        </tr>
        <tr v-for="rule in rules" :key="rule.id">
          <td class="w-0 gl-pr-4!">
            <approved-icon class="gl-pl-2" :is-approved="rule.approved" />
          </td>
          <td :colspan="numberOfColumns(rule)" class="gl-pl-0!">
            <div class="d-md-flex d-none js-name align-items-center">
              <empty-rule-name
                v-if="rule.type.toLowerCase() === $options.ruleTypeAnyApprover"
                :eligible-approvers-docs-path="eligibleApproversDocsPath"
              />
              <span v-else>
                <span
                  v-if="rule.section && rule.section !== 'codeowners'"
                  :aria-label="sectionNameLabel(rule)"
                  class="text-muted small d-block"
                  data-testid="rule-section"
                >
                  {{ rule.section }}
                </span>
                <span :class="rule.nameClass" :title="rule.name">{{ rule.name }}</span>
              </span>
              <approval-check-rule-popover
                :rule="rule"
                :code-coverage-check-help-page-path="codeCoverageCheckHelpPagePath"
              />
            </div>
            <div class="d-md-none d-flex flex-column js-summary">
              <empty-rule-name
                v-if="rule.type.toLowerCase() === $options.ruleTypeAnyApprover"
                :eligible-approvers-docs-path="eligibleApproversDocsPath"
              />
              <span v-else>{{ summaryText(rule) }}</span>
              <user-avatar-list
                v-if="!rule.fallback"
                class="mt-2"
                :items="rule.eligibleApprovers"
                :img-size="24"
                empty-text=""
              />
              <div v-if="rule.commentedBy.nodes.length > 0" class="gl-display-flex">
                <span class="gl-display-inline-flex gl-font-sm gl-text-gray-500">{{
                  s__('MRApprovals|Commented by')
                }}</span>
                <user-avatar-list
                  class="gl-display-inline-flex gl-align-items-center gl-ml-2"
                  :items="rule.commentedBy.nodes"
                  :img-size="16"
                />
              </div>
              <div v-if="rule.approvedBy.nodes.length" class="gl-display-flex">
                <span class="gl-display-inline-flex gl-font-sm gl-text-gray-500">{{
                  s__('MRApprovals|Approved by')
                }}</span>
                <user-avatar-list
                  class="gl-display-inline-flex gl-align-items-center gl-ml-2"
                  :items="rule.approvedBy.nodes"
                  :img-size="16"
                />
              </div>
            </div>
          </td>
          <td
            v-if="rule.type.toLowerCase() !== $options.ruleTypeAnyApprover"
            class="d-md-table-cell d-none gl-min-w-20 js-approvers"
          >
            <user-avatar-list
              :items="rule.eligibleApprovers"
              :img-size="24"
              empty-text=""
              class="gl-display-flex gl-flex-wrap"
            />
          </td>
          <td class="d-md-table-cell w-0 d-none gl-white-space-nowrap js-pending">
            <number-of-approvals :rule="rule" />
          </td>
          <td class="d-md-table-cell d-none js-commented-by">
            <user-avatar-list
              :items="rule.commentedBy.nodes"
              :img-size="24"
              empty-text=""
              class="gl-display-flex gl-flex-wrap"
            />
          </td>
          <td class="d-none d-md-table-cell js-approved-by">
            <user-avatar-list
              :items="rule.approvedBy.nodes"
              :img-size="24"
              empty-text=""
              class="gl-display-flex gl-flex-wrap"
            />
          </td>
        </tr>
      </tbody>
    </template>
  </table>
</template>
