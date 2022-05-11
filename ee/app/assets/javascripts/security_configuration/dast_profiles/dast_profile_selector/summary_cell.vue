<script>
export default {
  name: 'DastProfileSummaryCell',
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div v-if="value" class="row gl-my-2">
    <div class="col-md-6">{{ label }}:</div>
    <div class="col-md-6">
      <strong>{{ value }}</strong>
    </div>
  </div>
</template>
