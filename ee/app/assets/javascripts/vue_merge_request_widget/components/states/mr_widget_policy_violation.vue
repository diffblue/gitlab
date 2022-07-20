<script>
import StatusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetPolicyViolation',
  components: {
    StatusIcon,
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children gl-display-flex">
      <status-icon status="warning" show-disabled-button />
    </div>
    <div class="media-body">
      <span class="gl-ml-0! gl-text-body! gl-font-weight-bold gl-text-gray-700 gl-pl-2">
        {{ s__('mrWidget|Merge blocked: denied licenses must be removed.') }}
      </span>
    </div>
  </div>
</template>
