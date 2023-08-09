<script>
import { mapState, mapActions } from 'vuex';
import { __ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR, RULE_NAME_ANY_APPROVER } from '../../constants';
import EmptyRule from '../empty_rule.vue';
import RuleControls from '../rule_controls.vue';
import Rules from '../rules.vue';
import RuleInput from './rule_input.vue';

let targetBranchMutationObserver;

export default {
  components: {
    UserAvatarList,
    Rules,
    RuleControls,
    EmptyRule,
    RuleInput,
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: (state) => state.approvals.rules,
      targetBranch: (state) => state.approvals.targetBranch,
    }),
    hasNamedRule() {
      if (this.settings.allowMultiRule) {
        return this.rules.some((rule) => rule.ruleType !== RULE_TYPE_ANY_APPROVER);
      }

      const [rule] = this.rules;
      return rule.ruleType
        ? rule.ruleType === RULE_TYPE_REGULAR
        : rule.name !== RULE_NAME_ANY_APPROVER;
    },
    canEdit() {
      return this.settings.canEdit;
    },
    isEditPath() {
      return this.settings.mrSettingsPath;
    },
  },
  watch: {
    rules: {
      handler(newValue) {
        if (!this.settings.allowMultiRule && newValue.length === 0) {
          this.setEmptyRule();
        }
        if (
          this.settings.allowMultiRule &&
          !newValue.some((rule) => rule.ruleType === RULE_TYPE_ANY_APPROVER)
        ) {
          this.addEmptyRule();
        }
      },
      immediate: true,
    },
    targetBranch() {
      this.fetchRules({ targetBranch: this.targetBranch });
    },
  },
  mounted() {
    if (this.isEditPath) {
      this.mergeRequestTargetBranchElement = document.querySelector('#merge_request_target_branch');
      const targetBranch = this.mergeRequestTargetBranchElement?.value;

      this.setTargetBranch(targetBranch);

      if (targetBranch) {
        targetBranchMutationObserver = new MutationObserver(this.onTargetBranchMutation);
        targetBranchMutationObserver.observe(this.mergeRequestTargetBranchElement, {
          attributes: true,
          childList: false,
          subtree: false,
          attributeFilter: ['value'],
        });
      }
    }
  },
  beforeDestroy() {
    if (this.isEditPath && targetBranchMutationObserver) {
      targetBranchMutationObserver.disconnect();
      targetBranchMutationObserver = null;
    }
  },
  methods: {
    ...mapActions(['setEmptyRule', 'addEmptyRule', 'fetchRules', 'setTargetBranch']),
    onTargetBranchMutation() {
      const selectedTargetBranchValue = this.mergeRequestTargetBranchElement.value;

      if (this.targetBranch !== selectedTargetBranchValue) {
        this.setTargetBranch(selectedTargetBranchValue);
      }
    },
    indicatorText(rule) {
      if (rule.hasSource) {
        if (rule.overridden) {
          return __('Overridden');
        }
        return '';
      }
      return __('Added for this merge request');
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template #thead="{ name, members, approvalsRequired }">
      <tr>
        <th :class="hasNamedRule ? 'w-25' : 'w-75'">{{ hasNamedRule ? name : members }}</th>
        <th :class="hasNamedRule ? 'w-50' : null">
          <span v-if="hasNamedRule">{{ members }}</span>
        </th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template #tbody="{ rules }">
      <template v-for="(rule, index) in rules">
        <empty-rule
          v-if="rule.ruleType === 'any_approver'"
          :key="index"
          :rule="rule"
          :allow-multi-rule="settings.allowMultiRule"
          :eligible-approvers-docs-path="settings.eligibleApproversDocsPath"
          :can-edit="canEdit"
        />
        <tr v-else :key="index">
          <td>
            <div class="js-name" :data-label="__('Name')">{{ rule.name }}</div>
            <div ref="indicator" class="text-muted">{{ indicatorText(rule) }}</div>
          </td>
          <td class="js-members" :data-label="__('Approvers')">
            <user-avatar-list
              :items="rule.approvers"
              :img-size="24"
              :empty-text="__('Approvers from private group(s) not shown')"
            />
          </td>
          <td class="js-approvals-required gl-text-right" :data-label="__('Approvals required')">
            <rule-input :rule="rule" />
          </td>
          <td class="text-nowrap px-2 w-0 js-controls" :data-label="__('Actions')">
            <rule-controls v-if="canEdit" :rule="rule" />
          </td>
        </tr>
      </template>
    </template>
  </rules>
</template>
