<script>
import { GlAlert } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { GROUP_TYPE, ROLE_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import {
  APPROVER_TYPE_DICT,
  APPROVER_TYPE_LIST_ITEMS,
  removeAvailableApproverType,
  createActionFromApprovers,
  actionHasType,
} from '../lib/actions';
import PolicyActionApprovers from './action_approvers.vue';

export default {
  components: {
    GlAlert,
    PolicyActionApprovers,
  },
  inject: ['namespaceId'],
  props: {
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    initAction: {
      type: Object,
      required: true,
    },
    existingApprovers: {
      type: Object,
      required: true,
    },
  },
  data() {
    const approverTypeTracker = [];
    let availableApproverTypes = [...APPROVER_TYPE_LIST_ITEMS];
    [GROUP_TYPE, ROLE_TYPE, USER_TYPE].forEach((type) => {
      if (actionHasType(this.initAction, type)) {
        availableApproverTypes = removeAvailableApproverType(availableApproverTypes, type);
        approverTypeTracker.push({ id: uniqueId(), type });
      }
    });

    return {
      approverTypeTracker: approverTypeTracker.length ? approverTypeTracker : [{ id: uniqueId() }],
      availableApproverTypes,
    };
  },
  created() {
    this.updateRoleApprovers();
  },
  methods: {
    handleAddApproverType() {
      this.approverTypeTracker.push({ id: uniqueId() });
    },
    handleRemoveApproverType(approverIndex, approverType) {
      this.approverTypeTracker.splice(approverIndex, 1);

      if (approverType) {
        this.removeApproversByType(approverType);
      }
    },
    handleUpdateApprovalsRequired(value) {
      const updatedAction = { ...this.initAction, approvals_required: parseInt(value, 10) };
      this.updatePolicy(updatedAction);
    },
    handleUpdateApprovers(updatedExistingApprovers) {
      const updatedAction = createActionFromApprovers(this.initAction, updatedExistingApprovers);
      this.updatePolicy(updatedAction);
      this.$emit('updateApprovers', updatedExistingApprovers);
    },
    handleUpdateApproverType(approverIndex, { oldApproverType, newApproverType }) {
      this.approverTypeTracker[approverIndex].type = newApproverType;
      this.availableApproverTypes = removeAvailableApproverType(
        this.availableApproverTypes,
        newApproverType,
      );

      if (oldApproverType) {
        this.removeApproversByType(oldApproverType);
      }
    },
    removeApproversByType(approverType) {
      const updatedAction = Object.entries(this.initAction).reduce((acc, [key, value]) => {
        if (APPROVER_TYPE_DICT[approverType].includes(key)) {
          return acc;
        }

        acc[key] = value;
        return acc;
      }, {});
      this.updatePolicy(updatedAction);

      this.availableApproverTypes.push(
        APPROVER_TYPE_LIST_ITEMS.find((t) => t.value === approverType),
      );

      const updatedExistingApprovers = Object.keys(this.existingApprovers).reduce((acc, type) => {
        if (type !== approverType) {
          acc[type] = [...this.existingApprovers[type]];
        }
        return acc;
      }, {});
      this.$emit('updateApprovers', updatedExistingApprovers);
    },
    updatePolicy(updatedAction) {
      this.$emit('changed', updatedAction);
    },
    updateRoleApprovers() {
      const newApprovers = { ...this.existingApprovers };
      const roleApprovers = this.initAction[APPROVER_TYPE_DICT[ROLE_TYPE][0]];
      if (roleApprovers) {
        newApprovers[ROLE_TYPE] = roleApprovers;
      } else {
        delete newApprovers[ROLE_TYPE];
      }
      this.handleUpdateApprovers(newApprovers);
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-for="(error, index) in errors"
      :key="error.message"
      :class="{ 'gl-mb-3': index === errors.length - 1 }"
      :dismissible="false"
      :title="error.title"
      variant="danger"
    >
      {{ error.message }}
    </gl-alert>
    <div
      class="security-policies-bg-gray-10 gl-display-flex gl-flex-direction-column gl-gap-3 gl-rounded-base gl-py-5"
    >
      <policy-action-approvers
        v-for="({ id, type }, i) in approverTypeTracker"
        :key="id"
        :approver-index="i"
        :available-types="availableApproverTypes"
        :approver-type="type"
        :errors="errors"
        :num-of-approver-types="approverTypeTracker.length"
        :approvals-required="initAction.approvals_required"
        :existing-approvers="existingApprovers"
        @addApproverType="handleAddApproverType"
        @error="$emit('error')"
        @updateApprovers="handleUpdateApprovers"
        @updateApproverType="handleUpdateApproverType(i, $event)"
        @updateApprovalsRequired="handleUpdateApprovalsRequired"
        @removeApproverType="handleRemoveApproverType(i, $event)"
      />
    </div>
  </div>
</template>
