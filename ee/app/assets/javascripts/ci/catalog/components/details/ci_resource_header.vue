<script>
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
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
    name: {
      type: String,
      required: true,
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
    fullPath() {
      return `${this.rootNamespace.fullPath}/${this.rootNamespace.name}`;
    },
    entityId() {
      return getIdFromGraphQLId(this.resourceId);
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
      <div class="gl-display-flex gl-flex-direction-column gl-justify-content-center">
        <div class="gl-font-sm gl-text-secondary">
          {{ fullPath }}
        </div>
        <div class="gl-font-lg gl-font-weight-bold">{{ name }}</div>
      </div>
    </div>
    <p>
      {{ description }}
    </p>
  </div>
</template>
