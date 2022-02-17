<script>
import {
  GlSprintf,
  GlForm,
  GlFormInput,
  GlModalDirective,
  GlToken,
  GlAvatarLabeled,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { AVATAR_SHAPE_OPTION_CIRCLE, AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { groupApprovers, decomposeApprovers, USER_TYPE } from './lib/actions';

export default {
  components: {
    GlSprintf,
    GlForm,
    GlFormInput,
    GlToken,
    GlAvatarLabeled,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['projectId'],
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
    };
  },
  watch: {
    approvers(values) {
      this.action = decomposeApprovers(this.action, values);
    },
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
    removeApprover(removedApprover) {
      this.approvers = this.approvers.filter(
        (approver) => approver.type !== removedApprover.type || approver.id !== removedApprover.id,
      );
    },
    avatarShape(approver) {
      return this.isUser(approver) ? AVATAR_SHAPE_OPTION_CIRCLE : AVATAR_SHAPE_OPTION_RECT;
    },
    approverName(approver) {
      return this.isUser(approver) ? approver.name : approver.full_path;
    },
    isUser(approver) {
      return approver.type === USER_TYPE;
    },
  },
  i18n: {
    addAnApprover: s__('ScanResultPolicy|add an approver'),
  },
  humanizedTemplate: s__(
    'ScanResultPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require approval from %{approvalsRequired} of the following approvers: %{approvers}',
  ),
};
</script>

<template>
  <div
    class="gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base gl-px-5! gl-pt-5! gl-relative gl-pb-4"
  >
    <gl-form inline @submit.prevent>
      <gl-sprintf :message="$options.humanizedTemplate">
        <template #thenLabel="{ content }">
          <label for="approvalRequired" class="text-uppercase gl-font-lg gl-mr-3">{{
            content
          }}</label>
        </template>

        <template #approvalsRequired>
          <gl-form-input
            :value="action.approvals_required"
            type="number"
            class="gl-w-11! gl-m-3"
            :min="1"
            data-testid="approvals-required-input"
            @input="approvalsRequiredChanged"
          />
        </template>

        <template #approvers>
          <gl-token
            v-for="approver in approvers"
            :key="approver.type + approver.id"
            class="gl-ml-3"
            @close="removeApprover(approver)"
          >
            <gl-avatar-labeled
              :src="approver.avatar_url"
              :size="24"
              :shape="avatarShape(approver)"
              :label="approverName(approver)"
              :entity-name="approver.name"
              :alt="approver.name"
            />
          </gl-token>
        </template>
      </gl-sprintf>
    </gl-form>
  </div>
</template>
