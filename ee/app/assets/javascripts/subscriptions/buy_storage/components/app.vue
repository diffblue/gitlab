<script>
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';

export default {
  components: {
    StepOrderApp,
  },
};
</script>
<template>
  <step-order-app>
    <template #checkout></template>
    <template #order-summary></template>
  </step-order-app>
</template>
