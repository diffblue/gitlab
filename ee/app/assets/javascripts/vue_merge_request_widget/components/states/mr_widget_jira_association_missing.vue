<script>
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  name: 'MrWidgetJiraAssociationMissing',
  components: {
    StatusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon show-disabled-button status="warning" />
    <div class="media-body">
      <span class="gl-ml-0! gl-text-body! gl-font-weight-bold gl-text-gray-700">
        {{
          s__('mrWidget|To merge, a Jira issue key must be mentioned in the title or description.')
        }}
      </span>
    </div>
  </div>
</template>
