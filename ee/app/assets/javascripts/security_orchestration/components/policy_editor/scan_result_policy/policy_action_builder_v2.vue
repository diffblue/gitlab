<script>
import { GlSprintf, GlForm, GlFormInput, GlCollapsibleListbox, GlModalDirective } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import UserSelect from './user_select.vue';
import GroupSelect from './group_select.vue';
import {
  APPROVER_TYPE_LIST_ITEMS,
  decomposeApprovers,
  groupApproversV2,
  GROUP_TYPE,
  USER_TYPE,
} from './lib/actions';

export default {
  components: {
    GlSprintf,
    GlForm,
    GlFormInput,
    GlCollapsibleListbox,
    GroupSelect,
    UserSelect,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['namespaceId'],
  props: {
    initAction: {
      type: Object,
      required: true,
    },
    existingApprovers: {
      type: Array,
      required: true,
    },
  },
  data() {
    const action = { ...this.initAction };

    let approverType = '';
    if (action.user_approvers?.length || action.user_approvers_ids?.length) {
      approverType = USER_TYPE;
    } else if (action.group_approvers?.length || action.group_approvers_ids?.length) {
      approverType = GROUP_TYPE;
    }

    return {
      action,
      approvers: groupApproversV2(this.existingApprovers),
      approverType,
    };
  },
  computed: {
    approverTypeToggleText() {
      return this.approverType ? '' : s__('SecurityOrchestration|Choose approver type');
    },
    humanizedTemplate() {
      return n__(
        '%{thenLabelStart}Then%{thenLabelEnd} Require %{approvalsRequired} approval from %{approverType}%{approvers}',
        '%{thenLabelStart}Then%{thenLabelEnd} Require %{approvalsRequired} approvals from %{approverType}%{approvers}',
        this.action.approvals_required,
      );
    },
  },
  methods: {
    approvalsRequiredChanged(value) {
      this.action.approvals_required = parseInt(value, 10);
      this.handleActionUpdate();
    },
    handleActionUpdate() {
      this.$emit('changed', this.action);
    },
    handleApproversUpdate({ updatedApprovers, type }) {
      if (type === GROUP_TYPE) {
        this.approvers.groups = updatedApprovers;
      } else if (type === USER_TYPE) {
        this.approvers.users = updatedApprovers;
      }

      const allApprovers = [...this.approvers.groups, ...this.approvers.users];
      this.action = decomposeApprovers(this.action, allApprovers);
      this.$emit('approversUpdated', allApprovers);
      this.handleActionUpdate();
    },
  },
  APPROVER_TYPE_LIST_ITEMS,
  GROUP_TYPE,
  USER_TYPE,
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-display-flex gl-relative">
    <gl-form inline class="gl-flex-grow-1 gl-gap-3" @submit.prevent>
      <gl-sprintf :message="humanizedTemplate">
        <template #thenLabel="{ content }">
          <label for="approvalRequired" class="text-uppercase gl-font-lg gl-mr-3">{{
            content
          }}</label>
        </template>

        <template #approvalsRequired>
          <gl-form-input
            :value="action.approvals_required"
            type="number"
            class="gl-w-11!"
            :min="1"
            data-testid="approvals-required-input"
            @update="approvalsRequiredChanged"
          />
        </template>

        <template #approverType>
          <gl-collapsible-listbox
            v-model="approverType"
            :items="$options.APPROVER_TYPE_LIST_ITEMS"
            :toggle-text="approverTypeToggleText"
          />
        </template>

        <template #approvers>
          <template v-if="approverType === $options.USER_TYPE">
            <user-select
              :existing-approvers="approvers.users"
              @updateSelectedApprovers="
                handleApproversUpdate({ updatedApprovers: $event, type: $options.USER_TYPE })
              "
            />
          </template>
          <template v-else-if="approverType === $options.GROUP_TYPE">
            <group-select
              :existing-approvers="approvers.groups"
              @updateSelectedApprovers="
                handleApproversUpdate({ updatedApprovers: $event, type: $options.GROUP_TYPE })
              "
            />
          </template>
        </template>
      </gl-sprintf>
    </gl-form>
  </div>
</template>
