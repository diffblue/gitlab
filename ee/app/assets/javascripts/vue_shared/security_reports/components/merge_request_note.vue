<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';
import { __ } from '~/locale';

export default {
  components: {
    EventItem,
    GlSprintf,
    GlLink,
  },
  props: {
    feedback: {
      type: Object,
      required: true,
    },
    project: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    hasProjectUrl() {
      return Boolean(this.project?.value && this.project?.url);
    },
    eventText() {
      if (this.hasProjectUrl) {
        return __('Created merge request %{mergeRequestLink} at %{projectLink}');
      }

      return __('Created merge request %{mergeRequestLink}');
    },
    createdAt() {
      return this.feedback.created_at || this.feedback.createdAt;
    },
    mergeRequestPath() {
      return this.feedback.merge_request_path || this.feedback.mergeRequestPath;
    },
    mergeRequestIid() {
      return this.feedback.merge_request_iid || this.feedback.mergeRequestIid;
    },
  },
};
</script>

<template>
  <event-item :author="feedback.author" :created-at="createdAt" icon-name="merge-request">
    <gl-sprintf :message="eventText">
      <template #mergeRequestLink>
        <gl-link data-testid="mergeRequestLink" :href="mergeRequestPath">
          !{{ mergeRequestIid }}
        </gl-link>
      </template>
      <template v-if="hasProjectUrl" #projectLink>
        <gl-link data-testid="projectLink" :href="project.url">{{ project.value }}</gl-link>
      </template>
    </gl-sprintf>
  </event-item>
</template>
