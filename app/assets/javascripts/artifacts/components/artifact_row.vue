<script>
import { GlButtonGroup, GlButton, GlBadge } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { i18n } from '../constants';

export default {
  name: 'ArtifactRow',
  components: {
    GlButtonGroup,
    GlButton,
    GlBadge,
  },
  props: {
    artifact: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isExpired() {
      if (!this.artifact.expireAt) {
        return false;
      }
      return Date.now() > new Date(this.artifact.expireAt).getTime();
    },
    artifactSize() {
      return numberToHumanSize(this.artifact.size);
    },
  },
  i18n,
};
</script>
<template>
  <div class="gl-display-inline-flex gl-align-items-center gl-w-full">
    <span
      class="gl-w-40p gl-pl-8 gl-display-flex gl-align-items-center"
      data-testid="job-artifact-row-name"
    >
      {{ artifact.name }}
      <gl-badge size="sm" variant="neutral" class="gl-ml-2">
        {{ artifact.fileType.toLowerCase() }}
      </gl-badge>
      <gl-badge v-if="isExpired" size="sm" variant="warning" icon="expire" class="gl-ml-2">
        {{ $options.i18n.expired }}
      </gl-badge>
    </span>

    <span class="gl-w-quarter"></span>

    <span class="gl-w-10p gl-text-right gl-pr-5" data-testid="job-artifact-row-size">
      {{ artifactSize }}
    </span>

    <span class="gl-w-quarter gl-text-right gl-pr-5">
      <gl-button-group>
        <gl-button
          category="tertiary"
          icon="download"
          :title="$options.i18n.download"
          :aria-label="$options.i18n.download"
          :href="artifact.downloadPath"
          data-testid="job-artifact-row-download-button"
        />
        <gl-button
          category="tertiary"
          icon="remove"
          :title="$options.i18n.delete"
          :aria-label="$options.i18n.delete"
          :loading="isLoading"
          data-testid="job-artifact-row-delete-button"
          @click="$emit('delete')"
        />
      </gl-button-group>
    </span>
  </div>
</template>
