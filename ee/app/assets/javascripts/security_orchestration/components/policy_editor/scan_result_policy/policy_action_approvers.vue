<script>
import { GlButton, GlForm, GlFormInput, GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { GROUP_TYPE, ROLE_TYPE, USER_TYPE } from 'ee/security_orchestration/constants';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import GroupSelect from './group_select.vue';
import RoleSelect from './role_select.vue';
import UserSelect from './user_select.vue';
import {
  ADD_APPROVER_LABEL,
  APPROVER_TYPE_LIST_ITEMS,
  DEFAULT_APPROVER_DROPDOWN_TEXT,
  getDefaultHumanizedTemplate,
  MULTIPLE_APPROVER_TYPES_HUMANIZED_TEMPLATE,
} from './lib/actions';

export default {
  components: {
    BaseLayoutComponent,
    GlButton,
    GlForm,
    GlFormInput,
    GlCollapsibleListbox,
    GlSprintf,
    GroupSelect,
    RoleSelect,
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
      return this.approverType ? this.selected : DEFAULT_APPROVER_DROPDOWN_TEXT;
    },
    approverComponent() {
      switch (this.approverType) {
        case GROUP_TYPE:
          return GroupSelect;
        case ROLE_TYPE:
          return RoleSelect;
        case USER_TYPE:
        default:
          return UserSelect;
      }
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
    selected() {
      return APPROVER_TYPE_LIST_ITEMS.find((v) => v.value === this.approverType)?.text;
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
      updatedExistingApprovers[type] = updatedApprovers;
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
  i18n: {
    ADD_APPROVER_LABEL,
  },
};
</script>

<template>
  <base-layout-component
    class="gl-py-0 gl-rounded-0"
    :show-label="false"
    :show-remove-button="showRemoveButton"
    @remove="handleRemoveApprover"
  >
    <template #content>
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
          :selected="selected"
          :toggle-text="approverTypeToggleText"
          :disabled="!hasAvailableTypes"
          @select="handleSelectedApproverType"
        />

        <template v-if="approverType">
          <component
            :is="approverComponent"
            :existing-approvers="existingApprovers[approverType]"
            @updateSelectedApprovers="
              handleApproversUpdate({
                updatedApprovers: $event,
                type: approverType,
              })
            "
          />
        </template>
      </gl-form>
      <gl-button
        v-if="showAddButton"
        class="gl-ml-auto"
        variant="link"
        data-testid="add-approver"
        icon="plus"
        @click="addApproverType"
      >
        {{ $options.i18n.ADD_APPROVER_LABEL }}
      </gl-button>
    </template>
  </base-layout-component>
</template>
