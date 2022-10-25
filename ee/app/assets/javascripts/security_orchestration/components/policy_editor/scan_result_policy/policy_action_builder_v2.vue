<script>
import { GlSprintf, GlForm, GlFormInput, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import ApproversList from 'ee/approvals/components/approvers_list.vue';
import { groupApprovers, decomposeApprovers, groupIds, userIds } from './lib/actions';

export default {
  components: {
    GlSprintf,
    GlForm,
    GlFormInput,
    ApproversSelect,
    ApproversList,
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
      approversToAdd: [],
    };
  },
  computed: {
    groupIds() {
      return groupIds(this.approvers);
    },
    userIds() {
      return userIds(this.approvers);
    },
  },
  watch: {
    approvers(values) {
      this.action = decomposeApprovers(this.action, values);
      this.$emit('approversUpdated', this.approvers);
    },
    approversToAdd(val) {
      this.approvers.push(val[0]);
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
  },
  humanizedTemplate: s__(
    'ScanResultPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require approval from %{approvalsRequired} of the following approvers:',
  ),
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-px-5! gl-pt-5! gl-relative gl-pb-4">
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
            @update="approvalsRequiredChanged"
          />
        </template>
      </gl-sprintf>
      <div class="gl-bg-white gl-w-full gl-display-flex">
        <approvers-select
          v-model="approversToAdd"
          :skip-user-ids="userIds"
          :skip-group-ids="groupIds"
          :namespace-id="namespaceId"
          :namespace-type="namespaceType"
        />
      </div>
      <div class="gl-bg-white gl-w-full gl-mt-3 gl-border gl-rounded-base gl-overflow-auto gl-h-13">
        <approvers-list v-model="approvers" />
      </div>
    </gl-form>
  </div>
</template>
