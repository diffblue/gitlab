<script>
import { GlLink, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLink,
    GlEmptyState,
  },
  props: {
    imagePath: {
      type: String,
      required: true,
    },
  },
  strings: {
    heading: __("A merge request hasn't yet been merged"),
    subheading: __(
      'The compliance report captures merged changes that violate compliance best practices.',
    ),
    documentation: __('View documentation'),
  },
  documentationPath: 'https://docs.gitlab.com/ee/user/compliance/compliance_report/index.html',
};
</script>

<template>
  <gl-empty-state
    :title="$options.strings.heading"
    :description="$options.strings.subheading"
    :svg-path="imagePath"
  >
    <template #actions>
      <gl-link :href="$options.documentationPath">{{ $options.strings.documentation }}</gl-link>
    </template>
  </gl-empty-state>
</template>
