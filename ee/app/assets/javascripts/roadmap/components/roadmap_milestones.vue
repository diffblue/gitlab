<script>
import { GlFormGroup, GlFormRadioGroup, GlToggle } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import { __ } from '~/locale';
import { MILESTONES_OPTIONS } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    GlToggle,
  },
  computed: {
    ...mapState(['milestonesType', 'isShowingMilestones']),
  },
  methods: {
    ...mapActions(['setMilestonesType', 'toggleMilestones']),
    handleMilestonesChange(option) {
      if (option !== this.milestonesType) {
        this.setMilestonesType(option);
      }
    },
  },
  i18n: {
    header: __('Milestones'),
    toggleLabel: __('Display milestones'),
  },
  MILESTONES_OPTIONS,
  tracking: {
    label: 'roadmap_settings_milestones',
    property: 'toggle_milestones',
  },
};
</script>

<template>
  <div>
    <gl-form-group
      class="gl-mb-0"
      :label="$options.i18n.header"
      data-testid="roadmap-milestones-settings"
    >
      <gl-toggle
        :value="isShowingMilestones"
        :label="$options.i18n.toggleLabel"
        label-position="hidden"
        data-track-action="click_toggle"
        :data-track-label="$options.tracking.label"
        :data-track-property="$options.tracking.property"
        @change="toggleMilestones"
      />
      <gl-form-radio-group
        v-if="isShowingMilestones"
        :checked="milestonesType"
        stacked
        :options="$options.MILESTONES_OPTIONS"
        class="gl-mt-3"
        data-track-action="click_radio"
        :data-track-label="$options.tracking.label"
        :data-track-property="$options.tracking.property"
        @change="handleMilestonesChange"
      />
    </gl-form-group>
  </div>
</template>
