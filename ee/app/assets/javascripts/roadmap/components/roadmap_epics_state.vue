<script>
import { GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { __ } from '~/locale';

export default {
  components: {
    GlFormGroup,
    GlFormRadioGroup,
  },
  computed: {
    ...mapState(['epicsState']),
    availableStates() {
      const all = { text: __('Show all epics'), value: STATUS_ALL };
      const opened = { text: __('Show open epics'), value: STATUS_OPEN };
      const closed = { text: __('Show closed epics'), value: STATUS_CLOSED };

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
  <div>
    <gl-form-group class="gl-mb-0" :label="$options.i18n.header" data-testid="roadmap-epics-state">
      <gl-form-radio-group
        :checked="epicsState"
        stacked
        :options="availableStates"
        @change="handleEpicStateChange"
      />
    </gl-form-group>
  </div>
</template>
