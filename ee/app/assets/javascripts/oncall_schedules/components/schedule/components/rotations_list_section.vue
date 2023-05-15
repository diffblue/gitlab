<script>
import {
  GlButtonGroup,
  GlButton,
  GlLoadingIcon,
  GlTooltipDirective,
  GlModalDirective,
} from '@gitlab/ui';
import ScheduleShiftWrapper from 'ee/oncall_schedules/components/schedule/components/shifts/components/schedule_shift_wrapper.vue';
import {
  editRotationModalId,
  deleteRotationModalId,
  TIMELINE_CELL_WIDTH,
} from 'ee/oncall_schedules/constants';
import { s__ } from '~/locale';
import CurrentDayIndicator from './current_day_indicator.vue';

export const i18n = {
  editRotationLabel: s__('OnCallSchedules|Edit rotation'),
  deleteRotationLabel: s__('OnCallSchedules|Delete rotation'),
  addRotationLabel: s__('OnCallSchedules|Currently no rotation'),
};

export default {
  i18n,
  editRotationModalId,
  deleteRotationModalId,
  components: {
    GlButton,
    GlButtonGroup,
    GlLoadingIcon,
    CurrentDayIndicator,
    ScheduleShiftWrapper,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['userCanCreateSchedule'],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    presetType: {
      type: String,
      required: true,
    },
    rotations: {
      type: Array,
      required: true,
    },
    scheduleIid: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      rotationToUpdate: {},
    };
  },
  computed: {
    editRotationModalId() {
      return `${this.$options.editRotationModalId}-${this.scheduleIid}`;
    },
    deleteRotationModalId() {
      return `${this.$options.deleteRotationModalId}-${this.scheduleIid}`;
    },
    timelineStyles() {
      return {
        width: `calc(${100}% - ${TIMELINE_CELL_WIDTH}px)`,
      };
    },
  },
  methods: {
    setRotationToUpdate(rotation) {
      this.rotationToUpdate = rotation;
      this.$emit('set-rotation-to-update', rotation);
    },
  },
};
</script>

<template>
  <div class="list-section">
    <gl-loading-icon v-if="loading" size="sm" />
    <div v-else-if="rotations.length === 0 && !loading" class="gl-clearfix gl-border-t">
      <span
        class="details-cell gl-sticky gl-left-0 gl-float-left gl-display-flex gl-justify-content-space-between gl-align-items-center"
      >
        <span class="gl-text-truncate gl-text-gray-700">{{ $options.i18n.addRotationLabel }}</span>
      </span>
      <span
        class="timeline-cell gl-float-left gl-overflow-hidden gl-relative"
        :style="timelineStyles"
        data-testid="empty-timeline-cell"
      >
        <current-day-indicator
          :preset-type="presetType"
          :timeframe-item="timeframe[0]"
          :timeline-width="2"
        />
      </span>
    </div>
    <div v-else>
      <div v-for="rotation in rotations" :key="rotation.id" class="gl-clearfix gl-border-t">
        <span
          class="details-cell gl-sticky gl-left-0 gl-float-left gl-display-flex gl-justify-content-space-between gl-align-items-center"
        >
          <span
            v-gl-tooltip="{ boundary: 'viewport', title: rotation.name }"
            class="gl-text-truncate gl-text-gray-700"
            :aria-label="rotation.name"
            :data-testid="`rotation-name-${rotation.id}`"
            >{{ rotation.name }}</span
          >
          <gl-button-group
            v-if="userCanCreateSchedule"
            class="gl-px-2"
            data-testid="rotation-edit-button-group"
          >
            <gl-button
              v-gl-modal="editRotationModalId"
              v-gl-tooltip
              category="tertiary"
              :title="$options.i18n.editRotationLabel"
              icon="pencil"
              :aria-label="$options.i18n.editRotationLabel"
              @click="setRotationToUpdate(rotation)"
            />
            <gl-button
              v-gl-modal="deleteRotationModalId"
              v-gl-tooltip
              category="tertiary"
              :title="$options.i18n.deleteRotationLabel"
              icon="remove"
              :aria-label="$options.i18n.deleteRotationLabel"
              @click="setRotationToUpdate(rotation)"
            />
          </gl-button-group>
        </span>
        <span
          class="timeline-cell gl-float-left gl-overflow-hidden gl-relative"
          :style="timelineStyles"
          data-testid="timeline-cell"
        >
          <current-day-indicator
            :preset-type="presetType"
            :timeframe-item="timeframe[0]"
            :timeline-width="2"
          />
          <schedule-shift-wrapper
            v-if="rotation.shifts"
            :preset-type="presetType"
            :timeframe="timeframe"
            :rotation="rotation"
          />
        </span>
      </div>
    </div>
  </div>
</template>
