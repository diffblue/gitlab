<script>
import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg?raw';
import { GlIcon, GlLink, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { STATUS_CLOSED } from '~/issues/constants';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    isJira: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    iconName() {
      return this.issueIsClosed ? 'issue-closed' : 'issues';
    },
    issueIsClosed() {
      return this.issue.state === STATUS_CLOSED;
    },
  },
  jiraLogo,
};
</script>
<template>
  <gl-link
    v-gl-tooltip="issue.title"
    :href="issue.webUrl"
    target="__blank"
    class="gl-display-inline-flex gl-align-items-center gl-flex-shrink-0"
  >
    <span
      v-if="isJira"
      v-safe-html="$options.jiraLogo"
      class="gl-min-h-6 gl-mr-3 gl-display-inline-flex gl-align-items-center"
      data-testid="jira-logo"
    ></span>
    <gl-icon
      v-else
      class="gl-mr-2"
      :class="{ 'gl-text-green-600': !issueIsClosed }"
      :name="iconName"
    />
    <gl-sprintf v-if="issueIsClosed" :message="__('#%{issueIid} (closed)')">
      <template #issueIid>{{ issue.iid }}</template>
    </gl-sprintf>
    <span v-else>#{{ issue.iid }}</span>
    <gl-icon v-if="isJira" :size="12" name="external-link" class="gl-ml-1" />
  </gl-link>
</template>
