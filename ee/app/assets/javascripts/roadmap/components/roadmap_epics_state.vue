<script>
import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';

import { __ } from '~/locale';
import { EPICS_STATES } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormRadioGroup,
  },
  computed: {
    ...mapState(['epicsState']),
    availableStates() {
      const all = { text: __('Show all epics'), value: EPICS_STATES.ALL };
      const opened = { text: __('Show open epics'), value: EPICS_STATES.OPENED };
      const closed = { text: __('Show closed epics'), value: EPICS_STATES.CLOSED };

      return [all, opened, closed];
    },
  },
  methods: {
    ...mapActions(['setEpicsState', 'fetchEpics']),
    handleEpicStateChange(epicsState) {
      if (epicsState !== this.epicsState) {
        this.setEpicsState(epicsState);
        this.fetchEpics();
      }
    },
  },
  i18n: {
    header: __('Epics'),
  },
};
</script>

<template>
  <gl-form-group class="gl-mb-0" data-testid="roadmap-epics-state">
    <label for="roadmap-epics-state" class="gl-display-block">{{ $options.i18n.header }}</label>
    <gl-form-radio-group
      id="roadmap-epics-state"
      :checked="epicsState"
      stacked
      :options="availableStates"
      @change="handleEpicStateChange"
    />
  </gl-form-group>
</template>
