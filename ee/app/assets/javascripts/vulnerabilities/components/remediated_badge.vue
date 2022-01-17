<script>
import { GlPopover, GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlPopover,
    GlBadge,
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
};
</script>

<template>
  <div class="gl-display-inline-block">
    <gl-badge ref="badge" variant="info" icon="check-circle-dashed" />
    <gl-popover
      ref="popover"
      :content="
        __(
          'The vulnerability is no longer detected. Verify the vulnerability has been fixed or removed before changing its status.',
        )
      "
      :target="target"
      :title="__('Vulnerability remediated. Review before resolving.')"
      placement="top"
    />
  </div>
</template>
