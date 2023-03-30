<script>
import { s__ } from '~/locale';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

const message = s__(
  'mrWidget|%{boldStart}Merge blocked:%{boldEnd} a Jira issue key must be mentioned in the title or description.',
);

export default {
  name: 'MrWidgetJiraAssociationMissing',
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
  <state-container
    status="failed"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <bold-text :message="$options.message" />
  </state-container>
</template>
