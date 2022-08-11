<script>
import { GlAvatar, GlButton, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { n__, s__, sprintf } from '~/locale';
import Api from '~/api';

export default {
  components: {
    GlAvatar,
    GlButton,
    GlIcon,
    GlLink,
    GlPopover,
  },
  props: {
    accessLevels: {
      required: true,
      type: Array,
    },
    project: {
      required: true,
      type: String,
    },
    environment: {
      required: true,
      type: String,
    },
  },
  data() {
    return { groups: [], fails: [], loading: true };
  },
  computed: {
    toDeploy() {
      return n__('%d group', '%d groups', this.accessLevels.length);
    },
    title() {
      return sprintf(s__('ProtectedEnvironment|Allowed to deploy to %{project} / %{environment}'), {
        project: this.project,
        environment: this.environment,
      });
    },
    target() {
      return uniqueId('group-protected-environment-');
    },
  },
  mounted() {
    const promises = this.accessLevels
      .filter((level) => level.type === 'group')
      .map((level) =>
        Api.group(level.group_id)
          .then((data) => {
            this.groups.push(data);
          })
          .catch(() => {
            this.fails.push({
              id: level.group_id,
              text: s__('ProtectedEnvironment|Failed to load details for this group.'),
            });
          }),
      );

    return Promise.all(promises).finally(() => {
      this.loading = false;
    });
  },
};
</script>
<template>
  <div>
    <div :id="target">
      <gl-button category="tertiary" :loading="loading" :text="toDeploy">
        {{ toDeploy }} <gl-icon name="chevron-down" />
      </gl-button>
    </div>
    <gl-popover :target="target" :title="title">
      <div
        v-for="group in groups"
        :key="group.id"
        class="gl-display-flex gl-align-items-center gl-mb-4"
      >
        <gl-avatar
          :src="group.avatar_url"
          :size="16"
          :entity-id="group.id"
          :entity-name="group.name"
          shape="rect"
        />
        <gl-link :href="group.web_url" class="gl-ml-2">{{ group.full_name }}</gl-link>
      </div>
      <p v-for="fail in fails" :key="fail.id">{{ fail.text }}</p>
    </gl-popover>
  </div>
</template>
