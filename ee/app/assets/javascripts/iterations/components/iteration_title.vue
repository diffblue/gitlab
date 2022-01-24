<script>
export default {
  name: 'IterationTitle',
  props: {
    title: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-text-gray-400">
    {{ title }}
  </div>
</template>
