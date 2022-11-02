<script>
import { GlAlert } from '@gitlab/ui';
import { NO_CI_MINUTES_MSG } from '../constants';

export default {
  NO_CI_MINUTES_MSG,
  components: {
    GlAlert,
  },
};
</script>

<template>
  <gl-alert :dismissible="false">
    {{ $options.NO_CI_MINUTES_MSG }}
  </gl-alert>
</template>
