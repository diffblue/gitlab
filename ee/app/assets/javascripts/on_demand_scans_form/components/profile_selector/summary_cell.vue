<script>
import { __ } from '~/locale';

export default {
  name: 'OnDemandScansProfileSummaryCell',
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: __('None'),
    },
  },
};
</script>

<template>
  <div class="col-md-6">
    <div class="row gl-my-2">
      <div class="col-md-4">{{ label }}:</div>
      <div class="col-md-8">
        <strong data-testid="summary-value">{{ value }}</strong>
      </div>
    </div>
  </div>
</template>
