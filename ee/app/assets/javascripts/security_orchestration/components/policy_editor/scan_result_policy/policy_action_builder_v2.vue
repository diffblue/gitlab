<script>
import { GlSprintf, GlForm, GlFormInput, GlListbox, GlModalDirective } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import UserSelect from './user_select.vue';
import {
  APPROVER_TYPE_LIST_ITEMS,
  groupApprovers,
  decomposeApprovers,
  groupIds,
  userIds,
  USER_TYPE,
} from './lib/actions';

export default {
  components: {
    GlSprintf,
    GlForm,
    GlFormInput,
    GlListbox,
    UserSelect,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['namespaceId', 'namespaceType'],
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
    return {
      action: { ...this.initAction },
      approvers: groupApprovers(this.existingApprovers),
      approverType:
        this.initAction.user_approvers?.length || this.initAction.user_approvers_ids?.length
          ? USER_TYPE
          : '',
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
    groupIds() {
      return groupIds(this.approvers);
    },
    userIds() {
      return userIds(this.approvers);
    },
  },
  watch: {
    action: {
      handler(values) {
        this.$emit('changed', values);
      },
      deep: true,
    },
  },
  methods: {
    approvalsRequiredChanged(value) {
      this.action.approvals_required = parseInt(value, 10);
    },
    handleApproversUpdate(updatedApprovers) {
      this.approvers = updatedApprovers;
      this.action = decomposeApprovers(this.action, updatedApprovers);
      this.$emit('approversUpdated', this.approvers);
    },
  },
  APPROVER_TYPE_LIST_ITEMS,
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
          <gl-listbox
            v-model="approverType"
            :items="$options.APPROVER_TYPE_LIST_ITEMS"
            :toggle-text="approverTypeToggleText"
          />
        </template>

        <template #approvers>
          <template v-if="approverType === $options.USER_TYPE">
            <user-select
              :existing-approvers="approvers"
              @updateSelectedApprovers="handleApproversUpdate"
            />
          </template>
        </template>
      </gl-sprintf>
    </gl-form>
  </div>
</template>
