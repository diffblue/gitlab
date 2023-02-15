<script>
import { s__ } from '~/locale';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

const message = s__(
  'mrWidget|%{boldStart}Merge blocked:%{boldEnd} denied licenses must be removed.',
);

export default {
  name: 'MRWidgetPolicyViolation',
  message,
  components: {
    BoldText,
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
    <bold-text :message="$options.message" />
  </state-container>
</template>
