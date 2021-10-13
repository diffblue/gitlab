<script>
import { GlSegmentedControl } from '@gitlab/ui';
import { mergeUrlParams, redirectTo, getParameterByName } from '~/lib/utils/url_utility';
import { DATE_OPTIONS } from '../constants';

export default {
  name: 'DateSelector',
  dateOptions: DATE_OPTIONS,
  components: {
    GlSegmentedControl,
  },
  inject: {
    path: {
      default: '',
    },
  },
  data() {
    return {
      selectedDateOption: getParameterByName('start_date') || DATE_OPTIONS[0].value,
    };
  },
  methods: {
    loadPageWithDate(date) {
      redirectTo(mergeUrlParams({ start_date: date }, this.path));
    },
  },
};
</script>

<template>
  <gl-segmented-control
    :checked="selectedDateOption"
    :options="$options.dateOptions"
    @change="loadPageWithDate"
  />
</template>
