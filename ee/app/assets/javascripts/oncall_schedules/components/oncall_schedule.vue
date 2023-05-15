<script>
import {
  GlButton,
  GlButtonGroup,
  GlCard,
  GlCollapse,
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlCollapsibleListbox,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { capitalize } from 'lodash';
import {
  getStartOfWeek,
  formatDate,
  nWeeksBefore,
  nWeeksAfter,
  nDaysBefore,
  nDaysAfter,
} from '~/lib/utils/datetime_utility';
import { s__, __ } from '~/locale';
import {
  addRotationModalId,
  deleteRotationModalId,
  editRotationModalId,
  PRESET_TYPES,
} from '../constants';
import getShiftsForRotationsQuery from '../graphql/queries/get_oncall_schedules_with_rotations_shifts.query.graphql';
import EditScheduleModal from './add_edit_schedule_modal.vue';
import DeleteScheduleModal from './delete_schedule_modal.vue';
import AddEditRotationModal from './rotations/components/add_edit_rotation_modal.vue';
import DeleteRotationModal from './rotations/components/delete_rotation_modal.vue';
import RotationsListSection from './schedule/components/rotations_list_section.vue';
import ScheduleTimelineSection from './schedule/components/schedule_timeline_section.vue';
import { getTimeframeForWeeksView, selectedTimezoneFormattedOffset } from './schedule/utils';

export const i18n = {
  editScheduleLabel: s__('OnCallSchedules|Edit schedule'),
  deleteScheduleLabel: s__('OnCallSchedules|Delete schedule'),
  rotationTitle: s__('OnCallSchedules|Rotations'),
  addARotation: s__('OnCallSchedules|Add a rotation'),
  viewPreviousTimeframe: s__('OnCallSchedules|View previous timeframe'),
  viewNextTimeframe: s__('OnCallSchedules|View next timeframe'),
  presetTypeLabels: {
    DAYS: s__('OnCallSchedules|1 day'),
    WEEKS: s__('OnCallSchedules|2 weeks'),
  },
  scheduleOpen: s__('OnCallSchedules|Expand schedule'),
  scheduleClose: s__('OnCallSchedules|Collapse schedule'),
  moreActions: __('More actions'),
};
export const editScheduleModalId = 'editScheduleModal';
export const deleteScheduleModalId = 'deleteScheduleModal';

const editDeleteDisclosureItems = {
  edit: {
    text: i18n.editScheduleLabel,
  },
  delete: {
    text: i18n.deleteScheduleLabel,
  },
};
const presetListboxItems = [
  {
    text: i18n.presetTypeLabels.DAYS,
    value: PRESET_TYPES.DAYS,
  },
  {
    text: i18n.presetTypeLabels.WEEKS,
    value: PRESET_TYPES.WEEKS,
  },
];

export default {
  i18n,
  addRotationModalId,
  editRotationModalId,
  editScheduleModalId,
  deleteRotationModalId,
  deleteScheduleModalId,
  editDeleteDisclosureItems,
  presetListboxItems,
  PRESET_TYPES,
  components: {
    GlButton,
    GlButtonGroup,
    GlCard,
    GlCollapse,
    GlIcon,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlCollapsibleListbox,
    AddEditRotationModal,
    DeleteRotationModal,
    DeleteScheduleModal,
    EditScheduleModal,
    RotationsListSection,
    ScheduleTimelineSection,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'timezones', 'userCanCreateSchedule'],
  props: {
    schedule: {
      type: Object,
      required: true,
    },
    scheduleIndex: {
      type: Number,
      required: true,
    },
  },
  apollo: {
    rotations: {
      query: getShiftsForRotationsQuery,
      skip() {
        return !this.scheduleVisible;
      },
      variables() {
        this.timeframeStartDate.setHours(0, 0, 0, 0);
        const startsAt = this.timeframeStartDate;
        const endsAt =
          this.presetType === this.$options.PRESET_TYPES.WEEKS
            ? nWeeksAfter(startsAt, 2)
            : nDaysAfter(startsAt, 1);

        return {
          projectPath: this.projectPath,
          startsAt,
          endsAt,
          iids: [this.schedule.iid],
        };
      },
      update(data) {
        const nodes = data.project?.incidentManagementOncallSchedules?.nodes ?? [];
        const [schedule] = nodes;
        return schedule?.rotations.nodes ?? [];
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      presetType: this.$options.PRESET_TYPES.WEEKS,
      timeframeStartDate: getStartOfWeek(new Date()),
      rotations: this.schedule.rotations.nodes,
      rotationToUpdate: {},
      scheduleVisible: this.scheduleIndex === 0,
    };
  },
  computed: {
    addRotationModalId() {
      return `${this.$options.addRotationModalId}-${this.schedule.iid}`;
    },
    deleteScheduleModalId() {
      return `${this.$options.deleteScheduleModalId}-${this.schedule.iid}`;
    },
    deleteRotationModalId() {
      return `${this.$options.deleteRotationModalId}-${this.schedule.iid}`;
    },
    editScheduleModalId() {
      return `${this.$options.editScheduleModalId}-${this.schedule.iid}`;
    },
    editRotationModalId() {
      return `${this.$options.editRotationModalId}-${this.schedule.iid}`;
    },
    loading() {
      return this.$apollo.queries.rotations.loading;
    },
    offset() {
      return selectedTimezoneFormattedOffset(this.selectedTimezone.formatted_offset);
    },
    scheduleRange() {
      switch (this.presetType) {
        case PRESET_TYPES.DAYS:
          return formatDate(this.timeframe[0], 'mmmm d, yyyy');
        case PRESET_TYPES.WEEKS: {
          const firstDayOfTheLastWeek = this.timeframe[this.timeframe.length - 1];
          const firstDayOfTheNextTimeframe = nWeeksAfter(firstDayOfTheLastWeek, 1);
          const lastDayOfTimeframe = nDaysBefore(firstDayOfTheNextTimeframe, 1);

          return `${formatDate(this.timeframe[0], 'mmmm d')} - ${formatDate(
            lastDayOfTimeframe,
            'mmmm d, yyyy',
          )}`;
        }
        default:
          return '';
      }
    },
    scheduleInfo() {
      if (this.schedule.description) {
        return `${this.schedule.description} | ${this.offset} ${this.schedule.timezone}`;
      }
      return `${this.schedule.timezone} | ${this.offset}`;
    },
    scheduleVisibleAriaLabel() {
      return this.scheduleVisible
        ? this.$options.i18n.scheduleClose
        : this.$options.i18n.scheduleOpen;
    },
    scheduleVisibleAngleIcon() {
      return this.scheduleVisible ? 'chevron-lg-down' : 'chevron-lg-up';
    },
    selectedTimezone() {
      return this.timezones.find((tz) => tz.identifier === this.schedule.timezone);
    },
    timeframe() {
      return getTimeframeForWeeksView(this.timeframeStartDate);
    },
  },
  methods: {
    switchPresetType(type) {
      this.presetType = type;
      this.timeframeStartDate =
        type === PRESET_TYPES.WEEKS ? getStartOfWeek(new Date()) : new Date();
    },
    formatPresetType(type) {
      return capitalize(type);
    },
    updateToViewPreviousTimeframe() {
      switch (this.presetType) {
        case PRESET_TYPES.DAYS:
          this.timeframeStartDate = nDaysBefore(this.timeframeStartDate, 1);
          break;
        case PRESET_TYPES.WEEKS:
          this.timeframeStartDate = nWeeksBefore(this.timeframeStartDate, 2);
          break;
        default:
          break;
      }
    },
    updateToViewNextTimeframe() {
      switch (this.presetType) {
        case PRESET_TYPES.DAYS:
          this.timeframeStartDate = nDaysAfter(this.timeframeStartDate, 1);
          break;
        case PRESET_TYPES.WEEKS:
          this.timeframeStartDate = nWeeksAfter(this.timeframeStartDate, 2);
          break;
        default:
          break;
      }
    },
    onRotationUpdate(message) {
      this.$apollo.queries.rotations.refetch();
      this.$emit('rotation-updated', message);
    },
    onRotationDelete() {
      this.$apollo.queries.rotations.refetch();
    },
    setRotationToUpdate(rotation) {
      this.rotationToUpdate = rotation;
    },
  },
};
</script>

<template>
  <div>
    <gl-card
      class="gl-mt-5"
      :class="{ 'gl-border-bottom-0': !scheduleVisible }"
      body-class="gl-bg-gray-10 gl-py-0"
      :header-class="{ 'gl-bg-white': true, 'gl-rounded-small': !scheduleVisible }"
    >
      <template #header>
        <div class="gl-display-flex gl-align-items-flex-start" data-testid="schedule-header">
          <div class="gl-flex-grow-1">
            <h2 class="gl-font-weight-bold gl-m-0">{{ schedule.name }}</h2>
            <p class="gl-text-gray-500 gl-m-0">
              {{ scheduleInfo }}
            </p>
          </div>
          <gl-disclosure-dropdown
            v-if="userCanCreateSchedule"
            v-gl-tooltip.hover
            :title="$options.i18n.moreActions"
            toggle-class="gl-mr-2 gl-py-2!"
            class="gl-border-r"
            data-testid="schedule-edit-button-group"
            icon="ellipsis_v"
            category="tertiary"
            size="small"
            left
            text-sr-only
            no-caret
          >
            <gl-disclosure-dropdown-item
              :key="$options.i18n.editScheduleLabel"
              v-gl-modal="editScheduleModalId"
              :item="$options.editDeleteDisclosureItems.edit"
            />
            <gl-disclosure-dropdown-item
              :key="$options.i18n.deleteScheduleLabel"
              v-gl-modal="deleteScheduleModalId"
              :item="$options.editDeleteDisclosureItems.delete"
            />
          </gl-disclosure-dropdown>
          <gl-button
            v-gl-tooltip.hover
            :title="scheduleVisibleAriaLabel"
            :aria-label="scheduleVisibleAriaLabel"
            category="tertiary"
            size="small"
            class="gl-ml-2 gl-py-2"
            @click="scheduleVisible = !scheduleVisible"
          >
            <gl-icon :size="16" :name="scheduleVisibleAngleIcon" />
          </gl-button>
        </div>
      </template>
      <gl-collapse :visible="scheduleVisible">
        <div
          class="gl-mt-3 gl-display-flex gl-justify-content-space-between"
          data-testid="rotations-header"
        >
          <h3 class="gl-font-lg gl-m-0">{{ $options.i18n.rotationTitle }}</h3>
          <gl-button v-if="userCanCreateSchedule" v-gl-modal="addRotationModalId" variant="link"
            >{{ $options.i18n.addARotation }}
          </gl-button>
        </div>

        <hr class="gl-my-3" />

        <div class="gl-display-flex gl-align-items-center gl-mb-3">
          <gl-icon name="calendar" :size="14" class="gl-text-gray-700 gl-mr-2" />
          <div class="gl-flex-grow-1 gl-text-gray-700 gl-font-weight-bold">{{ scheduleRange }}</div>

          <gl-collapsible-listbox
            data-testid="shift-preset-change"
            :items="$options.presetListboxItems"
            :toggle-text="$options.i18n.presetTypeLabels[presetType]"
            :selected="presetType"
            size="small"
            @select="switchPresetType"
          />

          <gl-button-group class="gl-ml-3">
            <gl-button
              data-testid="previous-timeframe-btn"
              icon="chevron-left"
              size="small"
              :disabled="loading"
              :aria-label="$options.i18n.viewPreviousTimeframe"
              @click="updateToViewPreviousTimeframe"
            />
            <gl-button
              data-testid="next-timeframe-btn"
              icon="chevron-right"
              size="small"
              :disabled="loading"
              :aria-label="$options.i18n.viewNextTimeframe"
              @click="updateToViewNextTimeframe"
            />
          </gl-button-group>
        </div>

        <hr class="gl-my-3" />

        <div
          class="schedule-shell gl-relative gl-h-full gl-w-full gl-overflow-x-auto"
          data-testid="rotations-body"
        >
          <schedule-timeline-section :preset-type="presetType" :timeframe="timeframe" />
          <rotations-list-section
            :preset-type="presetType"
            :rotations="rotations"
            :timeframe="timeframe"
            :schedule-iid="schedule.iid"
            :loading="loading"
            @set-rotation-to-update="setRotationToUpdate"
          />
        </div>
      </gl-collapse>
    </gl-card>
    <delete-schedule-modal :schedule="schedule" :modal-id="deleteScheduleModalId" />
    <edit-schedule-modal :schedule="schedule" :modal-id="editScheduleModalId" is-edit-mode />
    <add-edit-rotation-modal
      :schedule="schedule"
      :modal-id="addRotationModalId"
      @rotation-updated="onRotationUpdate"
    />
    <add-edit-rotation-modal
      :schedule="schedule"
      :modal-id="editRotationModalId"
      :rotation="rotationToUpdate"
      is-edit-mode
      @rotation-updated="onRotationUpdate"
    />
    <delete-rotation-modal
      :rotation="rotationToUpdate"
      :schedule="schedule"
      :modal-id="deleteRotationModalId"
      @rotation-deleted="onRotationDelete"
    />
  </div>
</template>
