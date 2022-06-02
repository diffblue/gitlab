<script>
export default {
  props: {
    label: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <h5 data-testid="label" class="gl-mt-6">{{ label }}</h5>
    <p data-testid="content"><slot></slot></p>
  </div>
</template>
