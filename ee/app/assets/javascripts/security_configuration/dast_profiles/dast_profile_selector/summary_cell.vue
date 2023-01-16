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
      default: null,
    },
  },
};
</script>

<template>
  <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
  <div v-if="value || $slots.default" class="row gl-my-2">
    <div class="col-md-5 gl-pr-0!">{{ label }}:</div>
    <div class="col-md-7">
      <strong v-if="value">{{ value }}</strong>
      <slot v-else></slot>
    </div>
  </div>
</template>
