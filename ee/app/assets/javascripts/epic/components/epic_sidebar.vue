<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import AncestorsTree from 'ee/sidebar/components/ancestors_tree/ancestors_tree.vue';

import { TYPE_EPIC } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
import notesEventHub from '~/notes/event_hub';
import SidebarConfidentialityWidget from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import SidebarParticipants from '~/sidebar/components/participants/participants.vue';
import SidebarReferenceWidget from '~/sidebar/components/reference/sidebar_reference_widget.vue';
import SidebarSubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import sidebarEventHub from '~/sidebar/event_hub';
import SidebarDatePickerCollapsed from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';

import { dateTypes } from '../constants';
import epicUtils from '../utils/epic_utils';
import SidebarDatePicker from './sidebar_items/sidebar_date_picker.vue';
import SidebarHeader from './sidebar_items/sidebar_header.vue';
import SidebarLabels from './sidebar_items/sidebar_labels.vue';

export default {
  dateTypes,
  components: {
    SidebarHeader,
    SidebarDatePicker,
    SidebarDatePickerCollapsed,
    SidebarLabels,
    AncestorsTree,
    SidebarParticipants,
    SidebarConfidentialityWidget,
    SidebarSubscriptionsWidget,
    SidebarReferenceWidget,
    SidebarTodoWidget,
  },
  inject: ['iid'],
  data() {
    return {
      sidebarExpandedOnClick: false,
    };
  },
  computed: {
    ...mapState([
      'canUpdate',
      'allowSubEpics',
      'sidebarCollapsed',
      'participants',
      'startDateSourcingMilestoneTitle',
      'startDateSourcingMilestoneDates',
      'startDateIsFixed',
      'startDateFixed',
      'startDateFromMilestones',
      'dueDateSourcingMilestoneTitle',
      'dueDateSourcingMilestoneDates',
      'dueDateIsFixed',
      'dueDateFixed',
      'dueDateFromMilestones',
      'epicStartDateSaveInProgress',
      'epicDueDateSaveInProgress',
      'fullPath',
      'epicId',
    ]),
    ...mapGetters([
      'isUserSignedIn',
      'isDateInvalid',
      'startDateTimeFixed',
      'startDateTimeFromMilestones',
      'startDateTime',
      'startDateForCollapsedSidebar',
      'dueDateTimeFixed',
      'dueDateTimeFromMilestones',
      'dueDateTime',
      'dueDateForCollapsedSidebar',
      'ancestors',
    ]),
    issuableType() {
      return IssuableType.Epic;
    },
    fullEpicId() {
      return convertToGraphQLId(TYPE_EPIC, this.epicId);
    },
  },
  mounted() {
    this.toggleSidebarFlag(epicUtils.getCollapsedGutter());
    this.fetchEpicDetails();
    sidebarEventHub.$on('updateIssuableConfidentiality', this.updateEpicConfidentiality);
  },
  beforeDestroy() {
    sidebarEventHub.$off('updateIssuableConfidentiality', this.updateEpicConfidentiality);
  },
  methods: {
    ...mapActions([
      'fetchEpicDetails',
      'toggleSidebar',
      'toggleSidebarFlag',
      'toggleStartDateType',
      'toggleDueDateType',
      'saveDate',
      'updateConfidentialityOnIssuable',
    ]),
    getDateFromMilestonesTooltip(dateType) {
      return epicUtils.getDateFromMilestonesTooltip({
        dateType,
        startDateSourcingMilestoneTitle: this.startDateSourcingMilestoneTitle,
        startDateSourcingMilestoneDates: this.startDateSourcingMilestoneDates,
        startDateTimeFromMilestones: this.startDateTimeFromMilestones,
        dueDateSourcingMilestoneTitle: this.dueDateSourcingMilestoneTitle,
        dueDateSourcingMilestoneDates: this.dueDateSourcingMilestoneDates,
        dueDateTimeFromMilestones: this.dueDateTimeFromMilestones,
      });
    },
    changeStartDateType({ dateTypeIsFixed, typeChangeOnEdit }) {
      this.toggleStartDateType({ dateTypeIsFixed });
      if (!typeChangeOnEdit) {
        this.saveDate({
          newDate: dateTypeIsFixed ? this.startDateFixed : this.startDateFromMilestones,
          dateType: dateTypes.start,
          dateTypeIsFixed,
        });
      }
    },
    saveStartDate(date) {
      this.saveDate({
        dateType: dateTypes.start,
        newDate: date,
        dateTypeIsFixed: true,
      });
    },
    changeDueDateType({ dateTypeIsFixed, typeChangeOnEdit }) {
      this.toggleDueDateType({ dateTypeIsFixed });
      if (!typeChangeOnEdit) {
        this.saveDate({
          newDate: dateTypeIsFixed ? this.dueDateFixed : this.dueDateFromMilestones,
          dateType: dateTypes.due,
          dateTypeIsFixed,
        });
      }
    },
    saveDueDate(date) {
      this.saveDate({
        dateType: dateTypes.due,
        newDate: date,
        dateTypeIsFixed: true,
      });
    },
    updateEpicConfidentiality(confidential) {
      notesEventHub.$emit('notesApp.updateIssuableConfidentiality', confidential);
    },
    handleSidebarToggle() {
      if (this.sidebarCollapsed) {
        this.sidebarExpandedOnClick = true;
        this.toggleSidebar({ sidebarCollapsed: true });
      } else if (this.sidebarExpandedOnClick) {
        this.sidebarExpandedOnClick = false;
        this.toggleSidebar({ sidebarCollapsed: false });
      }
    },
  },
};
</script>

<template>
  <aside
    :class="{
      'right-sidebar-expanded': !sidebarCollapsed,
      'right-sidebar-collapsed': sidebarCollapsed,
    }"
    :data-signed-in="isUserSignedIn"
    class="right-sidebar epic-sidebar"
    :aria-label="__('Epic')"
  >
    <div class="issuable-sidebar js-issuable-update">
      <sidebar-header :sidebar-collapsed="sidebarCollapsed">
        <sidebar-todo-widget
          v-if="isUserSignedIn"
          :issuable-id="fullEpicId"
          :issuable-iid="String(iid)"
          :full-path="fullPath"
          :issuable-type="issuableType"
          data-testid="todo"
        />
      </sidebar-header>
      <sidebar-date-picker
        v-show="!sidebarCollapsed"
        :can-update="canUpdate"
        :sidebar-collapsed="sidebarCollapsed"
        :show-toggle-sidebar="!isUserSignedIn"
        :label="__('Start date')"
        :date-picker-label="__('Fixed start date')"
        :date-invalid-tooltip="
          __('This date is after the due date, so this epic won\'t appear in the roadmap.')
        "
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip($options.dateTypes.start)"
        :date-save-in-progress="epicStartDateSaveInProgress"
        :selected-date-is-fixed="startDateIsFixed"
        :date-fixed="startDateTimeFixed"
        :date-from-milestones="startDateTimeFromMilestones"
        :selected-date="startDateTime"
        :is-date-invalid="isDateInvalid"
        data-testid="start-date"
        block-class="start-date"
        @toggleCollapse="toggleSidebar({ sidebarCollapsed })"
        @toggleDateType="changeStartDateType"
        @saveDate="saveStartDate"
      />
      <sidebar-date-picker
        v-show="!sidebarCollapsed"
        :can-update="canUpdate"
        :sidebar-collapsed="sidebarCollapsed"
        :label="__('Due date')"
        :date-picker-label="__('Fixed due date')"
        :date-invalid-tooltip="
          __('This date is before the start date, so this epic won\'t appear in the roadmap.')
        "
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip($options.dateTypes.due)"
        :date-save-in-progress="epicDueDateSaveInProgress"
        :selected-date-is-fixed="dueDateIsFixed"
        :date-fixed="dueDateTimeFixed"
        :date-from-milestones="dueDateTimeFromMilestones"
        :selected-date="dueDateTime"
        :is-date-invalid="isDateInvalid"
        data-testid="due-date"
        block-class="due-date"
        @toggleDateType="changeDueDateType"
        @saveDate="saveDueDate"
      />
      <sidebar-date-picker-collapsed
        v-show="sidebarCollapsed"
        :collapsed="sidebarCollapsed"
        :min-date="startDateForCollapsedSidebar"
        :max-date="dueDateForCollapsedSidebar"
        @toggleCollapse="toggleSidebar({ sidebarCollapsed })"
      />
      <sidebar-labels
        :can-update="canUpdate"
        :sidebar-collapsed="sidebarCollapsed"
        data-testid="labels-select"
      />
      <sidebar-confidentiality-widget
        :iid="String(iid)"
        :full-path="fullPath"
        :issuable-type="issuableType"
        @closeForm="handleSidebarToggle"
        @expandSidebar="handleSidebarToggle"
        @confidentialityUpdated="updateConfidentialityOnIssuable($event)"
      />
      <div v-if="allowSubEpics" class="block ancestors">
        <ancestors-tree :ancestors="ancestors" :is-fetching="false" data-testid="ancestors" />
      </div>
      <div class="block participants">
        <sidebar-participants
          :participants="participants"
          @toggleSidebar="toggleSidebar({ sidebarCollapsed })"
        />
      </div>
      <sidebar-subscriptions-widget
        :iid="String(iid)"
        :full-path="fullPath"
        :issuable-type="issuableType"
        data-testid="subscribe"
        @expandSidebar="handleSidebarToggle"
      />
      <div class="block with-sub-blocks">
        <sidebar-reference-widget :issuable-type="issuableType" />
      </div>
    </div>
  </aside>
</template>
