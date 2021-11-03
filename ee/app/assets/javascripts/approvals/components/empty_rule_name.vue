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
  <div class="d-flex align-items-center">
    <span class="mt-n1">{{ __('Eligible users') }}</span>
    <span id="popovercontainer" class="ml-2 align-self-end">
      <gl-icon
        id="pop-approver"
        tabindex="0"
        name="question"
        :aria-label="__('help')"
        :size="14"
        class="author-link gl-cursor-help"
      />
      <gl-popover target="pop-approver" container="popovercontainer" placement="top">
        <template #title>{{ __('Who can approve?') }}</template>
        <ul class="pl-3">
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
