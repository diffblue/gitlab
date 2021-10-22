<script>
import { numberToHumanSize } from '~/lib/utils/number_utils';

export default {
  props: {
    name: {
      type: String,
      required: true,
    },
    value: {
      type: Number,
      required: true,
    },
  },
  computed: {
    formattedValue() {
      return numberToHumanSize(this.value);
    },
  },
};
</script>
<template>
  <div class="gl-responsive-table-row gl-line-height-normal" role="row">
    <div class="table-section section-wrap section-70 text-truncate pl-2 ml-3" role="gridcell">
      <div class="table-mobile-header" role="rowheader"></div>
      <div class="table-mobile-content ml-1">{{ name }}</div>
    </div>

    <div class="table-section section-wrap section-30 text-truncate" role="gridcell">
      <div class="table-mobile-header" role="rowheader"></div>
      <div class="table-mobile-content">{{ formattedValue }}</div>
    </div>
  </div>
</template>
