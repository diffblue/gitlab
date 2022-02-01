<script>
import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import { __ } from '~/locale';
import { PROGRESS_TRACKING_OPTIONS } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormRadioGroup,
  },
  computed: {
    ...mapState(['progressTracking']),
    availableOptions() {
      const weight = { text: __('Use issue weight'), value: PROGRESS_TRACKING_OPTIONS.WEIGHT };
      const count = { text: __('Use issue count'), value: PROGRESS_TRACKING_OPTIONS.COUNT };

      return [weight, count];
    },
  },
  methods: {
    ...mapActions(['setProgressTracking']),
    handleProgressTrackingChange(option) {
      if (option !== this.progressTracking) {
        this.setProgressTracking(option);
      }
    },
  },
  i18n: {
    header: __('Progress tracking'),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      class="gl-mb-0"
      :label="$options.i18n.header"
      data-testid="roadmap-progress-tracking"
    >
      <gl-form-radio-group
        :checked="progressTracking"
        stacked
        :options="availableOptions"
        @change="handleProgressTrackingChange"
      />
    </gl-form-group>
  </div>
</template>
