<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'ExternalIssueAlert',
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  props: {
    issueTrackerName: {
      type: String,
      required: true,
    },
    issueUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    alertTitle() {
      return sprintf(
        s__('ExternalIssueIntegration|This issue is synchronized with %{trackerName}'),
        { trackerName: this.issueTrackerName },
      );
    },
    alertMessage() {
      return sprintf(
        s__(
          `ExternalIssueIntegration|Not all data may be displayed here. To view more details or make changes to this issue, go to %{linkStart}%{trackerName}%{linkEnd}.`,
        ),
        { trackerName: this.issueTrackerName },
      );
    },
  },
};
</script>

<template>
  <gl-alert variant="info" :dismissible="false" :title="alertTitle" class="gl-mb-2">
    <gl-sprintf :message="alertMessage">
      <template #link="{ content }">
        <gl-link v-if="issueUrl" :href="issueUrl" target="_blank">{{ content }}</gl-link>
        <span v-else>{{ content }}</span>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
