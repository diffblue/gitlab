<script>
import { GlPopover, GlBadge, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOC_PATH_VULNERABILITY_DETAILS } from 'ee/security_dashboard/constants';

export default {
  components: {
    GlPopover,
    GlBadge,
    GlSprintf,
    GlLink,
  },
  inject: {
    canViewFalsePositive: {
      default: false,
    },
  },
  methods: {
    /**
     * BVPopover retrieves the target during the `beforeDestroy` hook to deregister attached
     * events. Since during `beforeDestroy` refs are `undefined`, it throws a warning in the
     * console because we're trying to access the `$el` property of `undefined`. Optional
     * chaining is not working in templates, which is why the method is used.
     *
     * See more on https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49628#note_464803276
     */
    target() {
      return this.$refs.badge?.$el;
    },
  },
  i18n: {
    title: s__('Vulnerability|False positive detected'),
    message: s__(
      'Vulnerability|The scanner determined this vulnerability to be a false positive. Verify the evaluation before changing its status. %{linkStart}Learn more about false positive detection.%{linkEnd}',
    ),
  },
  DOC_PATH_VULNERABILITY_DETAILS,
};
</script>

<template>
  <div v-if="canViewFalsePositive" class="gl-display-inline-block">
    <gl-badge ref="badge" icon="false-positive" variant="warning" />
    <gl-popover ref="popover" :target="target" :title="$options.i18n.title" placement="top">
      <gl-sprintf :message="$options.i18n.message">
        <template #link="{ content }">
          <gl-link
            class="gl-font-sm"
            :href="$options.DOC_PATH_VULNERABILITY_DETAILS"
            target="_blank"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-popover>
  </div>
</template>
