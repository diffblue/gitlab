<script>
import { GlButton, GlForm, GlFormInput, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import UserSelect from './user_select.vue';
import GroupSelect from './group_select.vue';
import {
  ADD_APPROVER_LABEL,
  APPROVER_TYPE_LIST_ITEMS,
  DEFAULT_APPROVER_DROPDOWN_TEXT,
  getDefaultHumanizedTemplate,
  groupApproversV2,
  GROUP_TYPE,
  MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE,
  USER_TYPE,
} from './lib/actions';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormInput,
    GlCollapsibleListbox,
    GlSprintf,
    GroupSelect,
    UserSelect,
  },
  inject: ['namespaceId'],
  props: {
    approverIndex: {
      type: Number,
      required: true,
    },
    approverTypes: {
      type: Array,
      required: true,
    },
    approvalsRequired: {
      type: Number,
      required: true,
    },
    existingApprovers: {
      type: Array,
      required: true,
    },
    numOfApproverTypes: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      approverType: '',
    };
  },
  computed: {
    approvers() {
      return groupApproversV2(this.existingApprovers);
    },
    approverTypeToggleText() {
      return this.approverType
        ? APPROVER_TYPE_LIST_ITEMS.find((v) => v.value === this.approverType).text
        : DEFAULT_APPROVER_DROPDOWN_TEXT;
    },
    humanizedTemplate() {
      return getDefaultHumanizedTemplate(this.approvalsRequired);
    },
    actionText() {
      return this.approverIndex === 0
        ? this.humanizedTemplate
        : MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE;
    },
    showAddButton() {
      return (
        this.approverIndex + 1 < APPROVER_TYPE_LIST_ITEMS.length &&
        this.approverIndex + 1 === this.numOfApproverTypes
      );
    },
  },
  methods: {
    addApproverType() {
      this.$emit('addApproverType');
    },
    approvalsRequiredChanged(value) {
      this.$emit('updateApprovalsRequired', parseInt(value, 10));
    },
    handleApproversUpdate({ updatedApprovers, type }) {
      let allApprovers;
      if (type === GROUP_TYPE) {
        allApprovers = [...updatedApprovers, ...this.approvers.users];
      } else if (type === USER_TYPE) {
        allApprovers = [...updatedApprovers, ...this.approvers.groups];
      }

      this.$emit('updateApprovers', allApprovers);
    },
    handleSelectedApproverType(type) {
      const oldApproverType = this.approverType;
      this.approverType = type;
      this.$emit('updateApproverType', { newApproverType: type, oldApproverType });
    },
    handleRemoveApprover() {
      this.$emit('removeApproverType', this.approverType);
    },
  },
  GROUP_TYPE,
  USER_TYPE,
  i18n: {
    ADD_APPROVER_LABEL,
  },
};
</script>

<template>
  <div>
    <gl-form inline class="gl-display-inline-block" @submit.prevent>
      <gl-sprintf :message="actionText">
        <template #require="{ content }">
          <strong>{{ content }}</strong>
        </template>

        <template #approvalsRequired>
          <gl-form-input
            :value="approvalsRequired"
            type="number"
            class="gl-w-11!"
            :min="1"
            data-testid="approvals-required-input"
            @update="approvalsRequiredChanged"
          />
        </template>

        <template #approval="{ content }">
          <strong>{{ content }}</strong>
        </template>

        <template #approverType>
          <gl-collapsible-listbox
            class="gl-mr-3"
            :items="approverTypes"
            :toggle-text="approverTypeToggleText"
            @select="handleSelectedApproverType"
          />
        </template>

        <template #approvers>
          <template v-if="approverType === $options.USER_TYPE">
            <user-select
              :existing-approvers="approvers.users"
              @updateSelectedApprovers="
                handleApproversUpdate({
                  updatedApprovers: $event,
                  type: $options.USER_TYPE,
                })
              "
            />
          </template>
          <template v-else-if="approverType === $options.GROUP_TYPE">
            <group-select
              :existing-approvers="approvers.groups"
              @updateSelectedApprovers="
                handleApproversUpdate({
                  updatedApprovers: $event,
                  type: $options.GROUP_TYPE,
                })
              "
            />
          </template>
        </template>
      </gl-sprintf>
    </gl-form>
    <gl-button
      v-if="showAddButton"
      variant="link"
      data-testid="add-approver"
      icon="plus"
      @click="addApproverType"
    >
      {{ $options.i18n.ADD_APPROVER_LABEL }}
    </gl-button>
    <gl-button
      v-if="numOfApproverTypes > 1"
      icon="remove"
      category="tertiary"
      data-testid="remove-approver"
      :aria-label="__('Remove')"
      @click="handleRemoveApprover"
    />
  </div>
</template>
