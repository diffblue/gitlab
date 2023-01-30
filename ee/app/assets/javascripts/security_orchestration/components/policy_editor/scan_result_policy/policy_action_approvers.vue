<script>
import { GlButton, GlForm, GlFormInput, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { GROUP_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import UserSelect from './user_select.vue';
import GroupSelect from './group_select.vue';
import {
  ADD_APPROVER_LABEL,
  APPROVER_TYPE_LIST_ITEMS,
  DEFAULT_APPROVER_DROPDOWN_TEXT,
  getDefaultHumanizedTemplate,
  MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE,
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
    availableTypes: {
      type: Array,
      required: true,
    },
    approvalsRequired: {
      type: Number,
      required: true,
    },
    existingApprovers: {
      type: Object,
      required: true,
    },
    numOfApproverTypes: {
      type: Number,
      required: true,
    },
    approverType: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    approverTypeToggleText() {
      return this.approverType
        ? APPROVER_TYPE_LIST_ITEMS.find((v) => v.value === this.approverType).text
        : DEFAULT_APPROVER_DROPDOWN_TEXT;
    },
    groupTypeApprovers() {
      return this.existingApprovers[GROUP_TYPE];
    },
    userTypeApprovers() {
      return this.existingApprovers[USER_TYPE];
    },
    hasAvailableTypes() {
      return Boolean(this.availableTypes.length);
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
    showRemoveButton() {
      return this.numOfApproverTypes > 1;
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
      const updatedExistingApprovers = { ...this.existingApprovers };
      if (type === GROUP_TYPE) {
        updatedExistingApprovers[GROUP_TYPE] = updatedApprovers;
      } else {
        updatedExistingApprovers[USER_TYPE] = updatedApprovers;
      }

      this.$emit('updateApprovers', updatedExistingApprovers);
    },
    handleSelectedApproverType(newType) {
      this.$emit('updateApproverType', {
        newApproverType: newType,
        oldApproverType: this.approverType,
      });
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
  <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-gap-3">
    <gl-form class="gl-display-flex gl-align-items-center" @submit.prevent>
      <div class="gl-display-flex gl-align-items-center gl-justify-content-end gl-w-30">
        <gl-sprintf :message="actionText">
          <template #require="{ content }">
            <strong>{{ content }}</strong>
          </template>

          <template #approvalsRequired>
            <gl-form-input
              :value="approvalsRequired"
              type="number"
              class="gl-w-11! gl-mx-3"
              :min="1"
              data-testid="approvals-required-input"
              @update="approvalsRequiredChanged"
            />
          </template>

          <template #approval="{ content }">
            <strong class="gl-mr-3">{{ content }}</strong>
          </template>
        </gl-sprintf>
      </div>

      <gl-collapsible-listbox
        class="gl-mx-3"
        :items="availableTypes"
        :toggle-text="approverTypeToggleText"
        :disabled="!hasAvailableTypes"
        @select="handleSelectedApproverType"
      />

      <template v-if="approverType === $options.USER_TYPE">
        <user-select
          :existing-approvers="userTypeApprovers"
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
          :existing-approvers="groupTypeApprovers"
          @updateSelectedApprovers="
            handleApproversUpdate({
              updatedApprovers: $event,
              type: $options.GROUP_TYPE,
            })
          "
        />
      </template>
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
      v-if="showRemoveButton"
      :key="approverType"
      icon="remove"
      category="tertiary"
      data-testid="remove-approver"
      :aria-label="__('Remove')"
      @click="handleRemoveApprover"
    />
  </div>
</template>
