<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';

const INPUT_ID = 'merge_request[approval_rules_attributes][][id]';
const INPUT_SOURCE_ID = 'merge_request[approval_rules_attributes][][approval_project_rule_id]';
const INPUT_NAME = 'merge_request[approval_rules_attributes][][name]';
const INPUT_APPROVALS_REQUIRED = 'merge_request[approval_rules_attributes][][approvals_required]';
const INPUT_USER_IDS = 'merge_request[approval_rules_attributes][][user_ids][]';
const INPUT_GROUP_IDS = 'merge_request[approval_rules_attributes][][group_ids][]';
const INPUT_DELETE = 'merge_request[approval_rules_attributes][][_destroy]';
const INPUT_REMOVE_HIDDEN_GROUPS =
  'merge_request[approval_rules_attributes][][remove_hidden_groups]';
const INPUT_FALLBACK_APPROVALS_REQUIRED = 'merge_request[approvals_before_merge]';
const INPUT_RESET_TO_DEFAULTS_ID = 'merge_request[reset_approval_rules_to_defaults]';

export default {
  computed: {
    ...mapState(['settings']),
    ...mapState({
      resetToDefault: (state) => state.approvals.resetToDefault,
      rules: (state) => state.approvals.rules,
      rulesToDelete: (state) => state.approvals.rulesToDelete,
      fallbackApprovalsRequired: (state) => state.approvals.fallbackApprovalsRequired,
    }),
  },
  mounted() {
    this.$root.$emit('hidden-inputs-mounted');
  },
  INPUT_ID,
  INPUT_SOURCE_ID,
  INPUT_NAME,
  INPUT_APPROVALS_REQUIRED,
  INPUT_USER_IDS,
  INPUT_GROUP_IDS,
  INPUT_DELETE,
  INPUT_REMOVE_HIDDEN_GROUPS,
  INPUT_FALLBACK_APPROVALS_REQUIRED,
  INPUT_RESET_TO_DEFAULTS_ID,
};
</script>

<template>
  <div v-if="settings.canEdit">
    <input
      v-if="resetToDefault"
      type="hidden"
      value="true"
      :name="$options.INPUT_RESET_TO_DEFAULTS_ID"
    />
    <div v-for="id in rulesToDelete" :key="id">
      <input :value="id" :name="$options.INPUT_ID" type="hidden" />
      <input :value="1" :name="$options.INPUT_DELETE" type="hidden" />
    </div>
    <input
      v-if="!rules.length"
      :value="fallbackApprovalsRequired"
      :name="$options.INPUT_FALLBACK_APPROVALS_REQUIRED"
      type="hidden"
    />
    <div v-for="rule in rules" :key="rule.id">
      <input v-if="!rule.isNew" :value="rule.id" :name="$options.INPUT_ID" type="hidden" />
      <input v-else :name="$options.INPUT_ID" type="hidden" />

      <input
        v-if="rule.isNew && rule.hasSource"
        :value="rule.sourceId"
        :name="$options.INPUT_SOURCE_ID"
        type="hidden"
      />
      <input
        :value="rule.approvalsRequired"
        :name="$options.INPUT_APPROVALS_REQUIRED"
        type="hidden"
      />
      <input :value="rule.name" :name="$options.INPUT_NAME" type="hidden" />
      <input
        v-if="!rule.users || rule.users.length === 0"
        value=""
        :name="$options.INPUT_USER_IDS"
        type="hidden"
      />
      <input
        v-for="user in rule.users"
        :key="user.id"
        :value="user.id"
        :name="$options.INPUT_USER_IDS"
        type="hidden"
      />
      <input
        v-if="!rule.groups || rule.groups.length === 0"
        value=""
        :name="$options.INPUT_GROUP_IDS"
        type="hidden"
      />
      <input
        v-for="group in rule.groups"
        :key="group.id"
        :value="group.id"
        :name="$options.INPUT_GROUP_IDS"
        type="hidden"
      />
      <input
        v-if="rule.removeHiddenGroups"
        value="true"
        :name="$options.INPUT_REMOVE_HIDDEN_GROUPS"
        type="hidden"
      />
    </div>
  </div>
</template>
