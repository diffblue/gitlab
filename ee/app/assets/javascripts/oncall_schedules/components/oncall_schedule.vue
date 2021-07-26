<script>
import {
  GlButton,
  GlButtonGroup,
  GlCard,
  GlCollapse,
  GlIcon,
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
import { s__ } from '~/locale';
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
};
export const editScheduleModalId = 'editScheduleModal';
export const deleteScheduleModalId = 'deleteScheduleModal';

export default {
  i18n,
  addRotationModalId,
  editRotationModalId,
  editScheduleModalId,
  deleteRotationModalId,
  deleteScheduleModalId,
  PRESET_TYPES,
  components: {
    GlButton,
    GlButtonGroup,
    GlCard,
    GlCollapse,
    GlIcon,
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
  inject: ['projectPath', 'timezones'],
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
      bodyClass: this.scheduleIndex === 0 ? 'gl-p-5' : 'gl-p-0',
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
      return this.scheduleVisible ? 'angle-down' : 'angle-right';
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
      :body-class="bodyClass"
      :header-class="{ 'gl-py-3': true, 'gl-rounded-small': !scheduleVisible }"
    >
      <template #header>
        <div class="gl-display-flex gl-align-items-center" data-testid="scheduleHeader">
          <gl-button
            v-gl-tooltip
            class="gl-mr-2 gl-p-0!"
            :title="scheduleVisibleAriaLabel"
            :aria-label="scheduleVisibleAriaLabel"
            category="tertiary"
            @click="scheduleVisible = !scheduleVisible"
          >
            <gl-icon :size="12" :name="scheduleVisibleAngleIcon" />
          </gl-button>
          <h3 class="gl-font-weight-bold gl-font-lg gl-m-0">{{ schedule.name }}</h3>
          <gl-button-group class="gl-ml-auto">
            <gl-button
              v-gl-modal="editScheduleModalId"
              v-gl-tooltip
              :title="$options.i18n.editScheduleLabel"
              icon="pencil"
              :aria-label="$options.i18n.editScheduleLabel"
            />
            <gl-button
              v-gl-modal="deleteScheduleModalId"
              v-gl-tooltip
              :title="$options.i18n.deleteScheduleLabel"
              icon="remove"
              :aria-label="$options.i18n.deleteScheduleLabel"
            />
          </gl-button-group>
        </div>
      </template>
      <gl-collapse
        :visible="scheduleVisible"
        @hidden="bodyClass = 'gl-p-0'"
        @show="bodyClass = 'gl-p-5'"
      >
        <p class="gl-text-gray-500 gl-mb-5" data-testid="scheduleBody">
          {{ scheduleInfo }}
        </p>
        <div class="gl-display-flex gl-justify-content-space-between gl-mb-3">
          <div class="gl-display-flex gl-align-items-center">
            <gl-button-group>
              <gl-button
                data-testid="previous-timeframe-btn"
                icon="chevron-left"
                :disabled="loading"
                :aria-label="$options.i18n.viewPreviousTimeframe"
                @click="updateToViewPreviousTimeframe"
              />
              <gl-button
                data-testid="next-timeframe-btn"
                icon="chevron-right"
                :disabled="loading"
                :aria-label="$options.i18n.viewNextTimeframe"
                @click="updateToViewNextTimeframe"
              />
            </gl-button-group>
            <div class="gl-ml-3">{{ scheduleRange }}</div>
          </div>
          <gl-button-group data-testid="shift-preset-change">
            <gl-button
              v-for="type in $options.PRESET_TYPES"
              :key="type"
              :selected="type === presetType"
              :title="formatPresetType(type)"
              @click="switchPresetType(type)"
            >
              {{ $options.i18n.presetTypeLabels[type] }}
            </gl-button>
          </gl-button-group>
        </div>

        <gl-card header-class="gl-bg-transparent">
          <template #header>
            <div
              class="gl-display-flex gl-justify-content-space-between"
              data-testid="rotationsHeader"
            >
              <h6 class="gl-m-0">{{ $options.i18n.rotationTitle }}</h6>
              <gl-button v-gl-modal="addRotationModalId" variant="link"
                >{{ $options.i18n.addARotation }}
              </gl-button>
            </div>
          </template>
          <div class="schedule-shell" data-testid="rotationsBody">
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
        </gl-card>
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
