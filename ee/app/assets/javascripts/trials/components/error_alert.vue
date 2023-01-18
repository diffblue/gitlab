<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'ErrorAlert',
  components: {
    GlAlert,
  },
  props: {
    errors: {
      type: String,
      required: true,
    },
  },
  i18n: {
    errorsFound: __('We have found the following errors:'),
  },
};
</script>

<template>
  <gl-alert
    variant="danger"
    :dismissible="false"
    class="gl-mt-3"
    :title="$options.i18n.errorsFound"
    data-testid="alert-danger"
  >
    {{ errors }}
  </gl-alert>
</template>
