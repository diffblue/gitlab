<script>
import { GlLink, GlSprintf, GlSkeletonLoader, GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { DISMISSAL_REASONS } from '../constants';

export default {
  components: {
    GlLink,
    GlSprintf,
    TimeAgoTooltip,
    GlSkeletonLoader,
    GlLoadingIcon,
    UserAvatarLink,
  },

  mixins: [glFeatureFlagsMixin()],

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
    state() {
      return this.vulnerability.state;
    },

    time() {
      return this.state === 'detected'
        ? this.vulnerability.pipeline?.createdAt
        : this.vulnerability[`${this.state}At`];
    },

    statusText() {
      switch (this.state) {
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

    dismissalReason() {
      return this.vulnerability.stateTransitions?.at(-1)?.dismissalReason;
    },

    hasDismissalReason() {
      return this.state === 'dismissed' && Boolean(this.dismissalReason);
    },

    dismissalReasonText() {
      return DISMISSAL_REASONS[this.dismissalReason];
    },

    shouldShowDismissalReason() {
      return this.glFeatures.dismissalReason;
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
          <template v-if="shouldShowDismissalReason && hasDismissalReason">
            {{ content }}: {{ dismissalReasonText }} &middot;
          </template>
          <template v-else>{{ content }} &middot;</template>
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
