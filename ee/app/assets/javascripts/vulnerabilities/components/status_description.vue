<script>
import { GlLink, GlSprintf, GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
    GlSkeletonLoader,
    GlLoadingIcon,
    UserAvatarLink,
  },

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: undefined,
    },
    isLoadingVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoadingUser: {
      type: Boolean,
      required: false,
      default: false,
    },
    isStatusBolded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    time() {
      const { state } = this.vulnerability;
      return state === 'detected'
        ? this.vulnerability.pipeline?.createdAt
        : this.vulnerability[`${this.vulnerability.state}At`];
    },

    statusText() {
      const { state } = this.vulnerability;

      switch (state) {
        case 'detected':
          return s__(
            'VulnerabilityManagement|%{statusStart}Detected%{statusEnd} %{timeago} in pipeline %{pipelineLink}',
          );
        case 'confirmed':
          return s__(
            'VulnerabilityManagement|%{statusStart}Confirmed%{statusEnd} %{timeago} by %{user}',
          );
        case 'dismissed':
          return s__(
            'VulnerabilityManagement|%{statusStart}Dismissed%{statusEnd} %{timeago} by %{user}',
          );
        case 'resolved':
          return s__(
            'VulnerabilityManagement|%{statusStart}Resolved%{statusEnd} %{timeago} by %{user}',
          );
        default:
          return '%timeago';
      }
    },
  },
};
</script>

<template>
  <span>
    <gl-skeleton-loader v-if="isLoadingVulnerability" :lines="2" class="h-auto" />
    <!-- there are cases in which `time` is undefined (e.g.: manually submitted vulnerabilities in "needs triage" state) -->
    <gl-sprintf v-else-if="time" :message="statusText">
      <template #status="{ content }">
        <span :class="{ 'gl-font-weight-bold': isStatusBolded }" data-testid="status">
          {{ content }}
        </span>
      </template>
      <template #timeago>
        <time-ago-tooltip ref="timeAgo" :time="time" />
      </template>
      <template #user>
        <gl-loading-icon v-if="isLoadingUser" class="d-inline ml-1" size="sm" />
        <user-avatar-link
          v-else-if="user"
          :link-href="user.web_url"
          :img-src="user.avatar_url"
          :img-size="24"
          :username="user.name"
          :data-user-id="user.id"
          class="font-weight-bold js-user-link"
          img-css-classes="avatar-inline"
        />
      </template>
      <template v-if="vulnerability.pipeline" #pipelineLink>
        <gl-link :href="vulnerability.pipeline.url" target="_blank" class="link">
          {{ vulnerability.pipeline.id }}
        </gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
