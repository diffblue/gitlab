<script>
import { __ } from '~/locale';
import SidebarDropdownWidget from '~/sidebar/components/sidebar_dropdown_widget.vue';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import {
  IssuableAttributeType,
  IssuableAttributeState,
  issuableAttributesQueries,
  SIDEBAR_ESCALATION_POLICY_TITLE,
} from '../constants';

const widgetTitleText = {
  [IssuableAttributeType.Milestone]: __('Milestone'),
  [IssuableAttributeType.Iteration]: __('Iteration'),
  [IssuableAttributeType.Epic]: __('Epic'),
  [IssuableAttributeType.EscalationPolicy]: SIDEBAR_ESCALATION_POLICY_TITLE,
  none: __('None'),
  expired: __('(expired)'),
};

export default {
  components: { SidebarDropdownWidget },
  provide: {
    issuableAttributesQueries,
    widgetTitleText,
    issuableAttributesState: IssuableAttributeState,
  },
  inheritAttrs: false,
  props: {
    issuableAttribute: {
      type: String,
      required: true,
      validator(value) {
        return [
          IssuableAttributeType.Milestone,
          IssuableAttributeType.Iteration,
          IssuableAttributeType.Epic,
          IssuableAttributeType.EscalationPolicy,
        ].includes(value);
      },
    },
    workspacePath: {
      required: true,
      type: String,
    },
    iid: {
      required: true,
      type: String,
    },
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [TYPE_ISSUE, TYPE_MERGE_REQUEST].includes(value);
      },
    },
    icon: {
      type: String,
      required: false,
      default: undefined,
    },
  },
};
</script>
<template>
  <sidebar-dropdown-widget
    :icon="icon"
    :issuable-type="issuableType"
    :attr-workspace-path="attrWorkspacePath"
    :issuable-attribute="issuableAttribute"
    :iid="iid"
    :workspace-path="workspacePath"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template v-for="(_, name) in $scopedSlots" #[name]="slotData">
      <slot :name="name" v-bind="slotData"></slot>
    </template>
  </sidebar-dropdown-widget>
</template>
