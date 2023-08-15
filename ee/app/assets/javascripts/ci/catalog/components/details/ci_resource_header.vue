<script>
import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { isNumeric } from '~/lib/utils/number_utils';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';

export default {
  components: {
    CiBadgeLink,
    GlAvatar,
    GlAvatarLink,
    GlBadge,
  },
  props: {
    description: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: false,
      default: '',
    },
    latestVersion: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    name: {
      type: String,
      required: true,
    },
    pipelineStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    resourceId: {
      type: String,
      required: true,
    },
    rootNamespace: {
      type: Object,
      required: true,
    },
    webPath: {
      required: true,
      type: String,
    },
  },
  computed: {
    entityId() {
      return getIdFromGraphQLId(this.resourceId);
    },
    fullPath() {
      return `${this.rootNamespace.fullPath}/${this.rootNamespace.name}`;
    },
    hasLatestVersion() {
      return this.latestVersion?.tagName;
    },
    hasPipelineStatus() {
      return this.pipelineStatus?.text;
    },
    versionBadgeText() {
      return isNumeric(this.latestVersion.tagName)
        ? `v${this.latestVersion.tagName}`
        : this.latestVersion.tagName;
    },
  },
};
</script>
<template>
  <div class="gl-border-b">
    <div class="gl-display-flex gl-py-5">
      <img />
      <gl-avatar-link :href="webPath">
        <gl-avatar
          class="gl-mr-4"
          :entity-id="entityId"
          :entity-name="name"
          shape="rect"
          :size="64"
          :src="icon"
        />
      </gl-avatar-link>
      <div
        class="gl-display-flex gl-flex-direction-column gl-align-items-flex-start gl-justify-content-center"
      >
        <div class="gl-font-sm gl-text-secondary">
          {{ fullPath }}
        </div>
        <span class="gl-display-flex">
          <div class="gl-font-lg gl-font-weight-bold">{{ name }}</div>
          <gl-badge
            v-if="hasLatestVersion"
            size="sm"
            class="gl-ml-3 gl-my-1"
            :href="latestVersion.tagPath"
          >
            {{ versionBadgeText }}
          </gl-badge>
        </span>
        <ci-badge-link
          v-if="hasPipelineStatus"
          class="gl-mt-2"
          :status="pipelineStatus"
          badge-size="sm"
          show-text
        />
      </div>
    </div>
    <p>
      {{ description }}
    </p>
  </div>
</template>
