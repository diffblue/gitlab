<script>
import { GlFormGroup, GlFormRadioGroup, GlToggle } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import { __ } from '~/locale';
import { PROGRESS_TRACKING_OPTIONS } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    GlToggle,
  },
  computed: {
    ...mapState(['progressTracking', 'isProgressTrackingActive']),
  },
  methods: {
    ...mapActions(['setProgressTracking', 'toggleProgressTrackingActive']),
    handleProgressTrackingChange(option) {
      if (option !== this.progressTracking) {
        this.setProgressTracking(option);
      }
    },
  },
  i18n: {
    header: __('Progress tracking'),
    toggleLabel: __('Display progress of child issues'),
  },
  PROGRESS_TRACKING_OPTIONS,
};
</script>

<template>
  <div>
    <gl-form-group
      class="gl-mb-0"
      :label="$options.i18n.header"
      label-class="gl-pb-2!"
      data-testid="roadmap-progress-tracking"
    >
      <gl-toggle
        :value="isProgressTrackingActive"
        :label="$options.i18n.toggleLabel"
        @change="toggleProgressTrackingActive"
      >
        <template #label>
          <span class="gl-font-weight-normal">{{ $options.i18n.toggleLabel }}</span>
        </template>
      </gl-toggle>
      <gl-form-radio-group
        v-if="isProgressTrackingActive"
        :checked="progressTracking"
        stacked
        :options="$options.PROGRESS_TRACKING_OPTIONS"
        class="gl-mt-3"
        @change="handleProgressTrackingChange"
      />
    </gl-form-group>
  </div>
</template>
