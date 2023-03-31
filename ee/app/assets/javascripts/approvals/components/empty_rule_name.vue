<script>
import { GlPopover, GlLink, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlPopover,
    GlLink,
  },
  props: {
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <span>{{ __('All eligible users') }}</span>
    <span id="popovercontainer" class="gl-display-inline-flex gl-ml-2">
      <gl-icon
        id="pop-approver"
        tabindex="0"
        name="question-o"
        :aria-label="__('help')"
        :size="14"
        class="author-link gl-cursor-help"
      />
      <gl-popover target="pop-approver" container="popovercontainer" placement="top">
        <template #title>{{ __('Who can approve?') }}</template>
        <ul class="gl-pl-5">
          <li>
            {{ __('Any member with at least Developer permissions on the project.') }}
          </li>
          <li>{{ __('Members listed as CODEOWNERS of affected files.') }}</li>
          <li>
            {{
              __("Users or groups set as approvers in the project's or merge request's settings.")
            }}
          </li>
        </ul>
        <gl-link :href="eligibleApproversDocsPath" class="text-1" target="_blank">{{
          __('More information')
        }}</gl-link>
      </gl-popover>
    </span>
  </div>
</template>
