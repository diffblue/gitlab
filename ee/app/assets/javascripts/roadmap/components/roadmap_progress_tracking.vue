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
  PROGRESS_TRACKING_OPTIONS,
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
        :options="$options.PROGRESS_TRACKING_OPTIONS"
        @change="handleProgressTrackingChange"
      />
    </gl-form-group>
  </div>
</template>
