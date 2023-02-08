<script>
import { s__ } from '~/locale';

export default {
  name: 'AutomationApp',
  i18n: {
    placeholder: s__('Automation|Automation App'),
  },
};
</script>

<template>
  <div>{{ $options.i18n.placeholder }}</div>
</template>
