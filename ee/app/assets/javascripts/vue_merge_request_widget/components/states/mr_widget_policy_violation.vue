<script>
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';

export default {
  name: 'MRWidgetPolicyViolation',
  components: {
    StateContainer,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <state-container :mr="mr" status="failed">
    <span class="gl-font-weight-bold">
      {{ s__('mrWidget|Merge blocked: denied licenses must be removed.') }}
    </span>
  </state-container>
</template>
