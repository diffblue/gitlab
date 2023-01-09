<script>
import { uniqueId } from 'lodash';
import PolicyActionApprovers from './policy_action_approvers.vue';
import { APPROVER_TYPE_DICT, APPROVER_TYPE_LIST_ITEMS, decomposeApprovers } from './lib/actions';

export default {
  components: {
    PolicyActionApprovers,
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
    return {
      approverTypeTracker: [uniqueId()],
      availableApproverTypes: [...APPROVER_TYPE_LIST_ITEMS],
    };
  },
  methods: {
    handleAddApproverType() {
      this.approverTypeTracker.push(uniqueId());
    },
    handleRemoveApproverType(approverIndex, approverType) {
      this.approverTypeTracker.splice(approverIndex, 1);

      if (approverType) {
        this.removeApproversByType(approverType);
      }
    },
    handleUpdateApprovalsRequired(value) {
      const updatedAction = { ...this.initAction, approvals_required: parseInt(value, 10) };
      this.updateAction(updatedAction);
    },
    handleUpdateApprovers(values) {
      const updatedAction = decomposeApprovers(this.initAction, values);
      this.updateAction(updatedAction);
      this.$emit('updateApprovers', values);
    },
    handleUpdateApproverType({ oldApproverType, newApproverType }) {
      this.availableApproverTypes = this.availableApproverTypes.filter(
        (t) => t.value !== newApproverType,
      );

      if (oldApproverType) {
        this.removeApproversByType(oldApproverType);
      }
    },
    removeApproversByType(approverType) {
      const action = { ...this.initAction };
      APPROVER_TYPE_DICT[approverType].forEach((a) => {
        if (action[a]) {
          delete action[a];
        }
      });
      this.updateAction(action);

      this.availableApproverTypes.push(
        APPROVER_TYPE_LIST_ITEMS.find((t) => t.value === approverType),
      );

      this.handleUpdateApprovers(this.existingApprovers.filter((a) => a.type !== approverType));
    },
    updateAction(updatedAction) {
      this.$emit('changed', updatedAction);
    },
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-relative gl-pt-5 gl-pr-7 gl-pb-4 gl-pl-5">
    <policy-action-approvers
      v-for="(val, i) in approverTypeTracker"
      :key="val"
      class="gl-mb-4"
      :approver-index="i"
      :approver-types="availableApproverTypes"
      :num-of-approver-types="approverTypeTracker.length"
      :approvals-required="initAction.approvals_required"
      :existing-approvers="existingApprovers"
      @addApproverType="handleAddApproverType"
      @updateApprovers="handleUpdateApprovers"
      @updateApproverType="handleUpdateApproverType"
      @updateApprovalsRequired="handleUpdateApprovalsRequired"
      @removeApproverType="handleRemoveApproverType(i, $event)"
    />
  </div>
</template>
