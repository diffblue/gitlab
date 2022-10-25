<script>
export default {
  name: 'TimePeriodHeader',
  props: {
    name: {
      type: String,
      required: true,
    },
    startDate: {
      type: String,
      required: true,
    },
    endDate: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <span class="gl-display-block gl-mb-2">{{ name }}</span>
    <span class="gl-display-block gl-font-weight-normal">{{ startDate }} - {{ endDate }}</span>
  </div>
</template>
