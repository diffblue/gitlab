<script>
import RotationAssignee from 'ee/oncall_schedules/components/rotations/components/rotation_assignee.vue';
import { getShiftContainerStyles } from './shift_utils';

export default {
  components: {
    RotationAssignee,
  },
  props: {
    shift: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    presetType: {
      type: String,
      required: true,
    },
    timelineWidth: {
      type: Number,
      required: true,
    },
    shiftColor: {
      type: Object,
      required: true,
    },
  },
  computed: {
    containerStyle() {
      const { timeframe, presetType, timelineWidth, shift } = this;
      return getShiftContainerStyles({ timeframe, presetType, timelineWidth, shift });
    },
  },
};
</script>

<template>
  <rotation-assignee
    :assignee="shift.participant"
    :container-style="containerStyle"
    :starts-at="shift.startsAt"
    :ends-at="shift.endsAt"
    :color="shiftColor"
  />
</template>
