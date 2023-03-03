<script>
import { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER } from '../../constants';

export default {
  i18n: { USAGE_BY_MONTH_HEADER, USAGE_BY_PROJECT_HEADER },
  inject: ['fullPath'],
};
</script>

<template>
  <div>
    <h4 class="gl-font-lg gl-mb-5">{{ $options.i18n.USAGE_BY_MONTH_HEADER }}</h4>
    <h4 class="gl-font-lg gl-mb-5">{{ $options.i18n.USAGE_BY_PROJECT_HEADER }}</h4>
  </div>
</template>
