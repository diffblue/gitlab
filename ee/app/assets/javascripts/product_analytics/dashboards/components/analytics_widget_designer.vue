<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'AnalyticsWidgetDesigner',
  components: {
    GlButton,
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-mb-4 gl-mt-4">
      <div class="gl-flex-direction-column gl-flex-grow-1">
        <input
          dir="auto"
          type="text"
          :placeholder="s__('ProductAnalytics|New Analytics Widget Title')"
          :aria-label="__('Title')"
          class="form-control gl-border-gray-200"
          data-testid="widget-title-tba"
        />
      </div>
      <div class="gl-ml-2">
        <gl-button disabled category="primary">{{
          s__('ProductAnalytics|Add to Dashboard')
        }}</gl-button>
      </div>
    </div>
    <div></div>
  </div>
</template>
