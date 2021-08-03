<script>
import { GlLoadingIcon, GlButton, GlIcon, GlTooltipDirective, GlPopover, GlLink } from '@gitlab/ui';
import { uniqueId } from 'lodash';

import { dateInWords } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';

import DatePicker from '~/vue_shared/components/pikaday.vue';
import CollapsedCalendarIcon from '~/vue_shared/components/sidebar/collapsed_calendar_icon.vue';
import ToggleSidebar from '~/vue_shared/components/sidebar/toggle_sidebar.vue';

const label = __('Date picker');
const pickerLabel = __('Fixed date');

export default {
  dateHelpUrl: '/help/user/group/epics/index.md#start-date-and-due-date',
  dateHelpValidMessage: s__(
    'Epics|These dates affect how your epics appear in the roadmap. Dates from milestones come from the milestones assigned to issues in the epic. You can also set fixed dates or remove them entirely.',
  ),
  dateHelpInvalidUrlText: s__('Epics|How can I solve this?'),
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    DatePicker,
    CollapsedCalendarIcon,
    ToggleSidebar,
    GlLoadingIcon,
    GlButton,
    GlPopover,
    GlLink,
  },
  props: {
    sidebarCollapsed: {
      type: Boolean,
      required: false,
      default: true,
    },
    label: {
      type: String,
      required: false,
      default: label,
    },
    datePickerLabel: {
      type: String,
      required: false,
      default: pickerLabel,
    },
    dateInvalidTooltip: {
      type: String,
      required: false,
      default: '',
    },
    blockClass: {
      type: String,
      required: false,
      default: '',
    },
    showToggleSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
    dateSaveInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedDateIsFixed: {
      type: Boolean,
      required: false,
      default: true,
    },
    dateFixed: {
      type: Date,
      required: false,
      default: null,
    },
    dateFromMilestones: {
      type: Date,
      required: false,
      default: null,
    },
    selectedDate: {
      type: Date,
      required: false,
      default: null,
    },
    dateFromMilestonesTooltip: {
      type: String,
      required: false,
      default: '',
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDateInvalid: {
      type: Boolean,
      required: false,
      default: true,
    },
    fieldName: {
      type: String,
      required: false,
      default: () => uniqueId('dateType_'),
    },
  },
  data() {
    return {
      editing: false,
    };
  },
  computed: {
    selectedAndEditable() {
      return this.selectedDate && this.canUpdate;
    },
    selectedDateWords() {
      return dateInWords(this.selectedDate, true);
    },
    dateFixedWords() {
      return dateInWords(this.dateFixed, true);
    },
    dateFromMilestonesWords() {
      return this.dateFromMilestones ? dateInWords(this.dateFromMilestones, true) : __('None');
    },
    collapsedText() {
      return this.selectedDateWords ? this.selectedDateWords : __('None');
    },
  },
  methods: {
    stopEditing() {
      this.editing = false;
      this.$emit('toggleDateType', { dateTypeIsFixed: true, typeChangeOnEdit: true });
    },
    startEditing(e) {
      this.editing = true;
      e.stopPropagation();
    },
    newDateSelected(date = null) {
      this.editing = false;
      this.$emit('saveDate', date);
    },
    toggleDateType(dateTypeFixed) {
      this.$emit('toggleDateType', { dateTypeIsFixed: dateTypeFixed });
    },
    toggleSidebar() {
      this.$emit('toggleCollapse');
    },
  },
};
</script>

<template>
  <div :class="blockClass" class="block date">
    <collapsed-calendar-icon :text="collapsedText" class="sidebar-collapsed-icon" />
    <div class="title gl-mb-2">
      {{ label }}
      <gl-loading-icon v-if="dateSaveInProgress" size="sm" :inline="true" />
      <div class="float-right gl-display-flex gl-align-items-center">
        <gl-icon
          ref="epicDatePopover"
          name="question-o"
          class="help-icon gl-mr-2"
          tabindex="0"
          :aria-label="__('Help')"
        />
        <gl-popover
          :target="() => $refs.epicDatePopover.$el"
          triggers="focus"
          placement="left"
          boundary="viewport"
        >
          <p>{{ $options.dateHelpValidMessage }}</p>
          <gl-link :href="$options.dateHelpUrl" target="_blank">{{
            __('More information')
          }}</gl-link>
        </gl-popover>
        <gl-button
          v-show="canUpdate && !editing"
          ref="editButton"
          category="tertiary"
          size="small"
          class="btn-sidebar-action gl-mr-n2"
          @click="startEditing"
        >
          {{ __('Edit') }}
        </gl-button>

        <toggle-sidebar
          v-if="showToggleSidebar"
          :collapsed="sidebarCollapsed"
          @toggle="toggleSidebar"
        />
      </div>
    </div>
    <div class="value">
      <div
        :class="{ 'is-option-selected': selectedDateIsFixed, 'd-flex': !editing }"
        class="value-type-fixed text-secondary"
      >
        <input
          v-if="canUpdate && !editing"
          :name="fieldName"
          :checked="selectedDateIsFixed"
          type="radio"
          @click="toggleDateType(true)"
        />
        <span v-show="!editing" class="gl-ml-2">{{ __('Fixed:') }}</span>
        <date-picker
          v-if="editing"
          :selected-date="dateFixed"
          :label="datePickerLabel"
          @newDateSelected="newDateSelected"
          @hidePicker="stopEditing"
        />
        <span v-else class="d-flex value-content gl-ml-1">
          <template v-if="dateFixed">
            <span>{{ dateFixedWords }}</span>
            <template v-if="isDateInvalid && selectedDateIsFixed">
              <gl-icon
                ref="fixedDatePopoverWarning"
                name="warning"
                class="date-warning-icon gl-mr-2 gl-ml-2"
                tabindex="0"
                :aria-label="__('Warning')"
              />
              <gl-popover
                :target="() => $refs.fixedDatePopoverWarning.$el"
                triggers="focus"
                placement="left"
                boundary="viewport"
              >
                <p>
                  {{ dateInvalidTooltip }}
                </p>
                <gl-link :href="$options.dateHelpUrl" target="_blank">{{
                  $options.dateHelpInvalidUrlText
                }}</gl-link>
              </gl-popover>
            </template>

            <span v-if="selectedAndEditable" class="no-value d-flex">
              &nbsp;&ndash;&nbsp;
              <gl-button
                ref="removeButton"
                variant="link"
                class="btn-sidebar-date-remove"
                @click="newDateSelected(null)"
              >
                {{ __('remove') }}
              </gl-button>
            </span>
          </template>
          <span v-else class="no-value"> {{ __('None') }} </span>
        </span>
      </div>
      <abbr
        v-gl-tooltip.bottom.html
        :title="dateFromMilestonesTooltip"
        :class="{ 'is-option-selected': !selectedDateIsFixed }"
        class="value-type-dynamic text-secondary d-flex gl-mt-3"
      >
        <input
          v-if="canUpdate"
          :name="fieldName"
          :checked="!selectedDateIsFixed"
          type="radio"
          @click="toggleDateType(false)"
        />
        <span class="gl-ml-2">{{ __('Inherited:') }}</span>
        <span class="value-content gl-ml-1">{{ dateFromMilestonesWords }}</span>
        <template v-if="isDateInvalid && !selectedDateIsFixed">
          <gl-icon
            ref="datePopoverWarning"
            name="warning"
            class="date-warning-icon gl-ml-2"
            tabindex="0"
            :aria-label="__('Warning')"
          />
          <gl-popover
            :target="() => $refs.datePopoverWarning.$el"
            triggers="focus"
            placement="left"
            boundary="viewport"
          >
            <p>
              {{ dateInvalidTooltip }}
            </p>
            <gl-link :href="$options.dateHelpUrl" target="_blank">{{
              $options.dateHelpInvalidUrlText
            }}</gl-link>
          </gl-popover>
        </template>
      </abbr>
    </div>
  </div>
</template>
