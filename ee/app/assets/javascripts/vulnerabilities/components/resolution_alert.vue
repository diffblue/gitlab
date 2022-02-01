<script>
import { GlAlert } from '@gitlab/ui';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { __, sprintf } from '~/locale';

export const COOKIE_NAME = 'dismissed_resolution_alerts';

export default {
  components: {
    GlAlert,
  },
  props: {
    defaultBranchName: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isVisible: this.isAlreadyDismissed() === false,
    };
  },
  computed: {
    resolutionTitle() {
      return this.defaultBranchName
        ? sprintf(__(`Vulnerability resolved in %{branch}`), { branch: this.defaultBranchName })
        : __('Vulnerability resolved in the default branch');
    },
  },
  methods: {
    alreadyDismissedVulnerabilities() {
      try {
        return JSON.parse(getCookie(COOKIE_NAME));
      } catch (e) {
        return [];
      }
    },
    isAlreadyDismissed() {
      return this.alreadyDismissedVulnerabilities().some((id) => id === this.vulnerabilityId);
    },
    dismiss() {
      const dismissed = this.alreadyDismissedVulnerabilities().concat(this.vulnerabilityId);
      setCookie(COOKIE_NAME, JSON.stringify(dismissed), { expires: 90 });
      this.isVisible = false;
    },
  },
};
</script>
<template>
  <gl-alert v-if="isVisible" :title="resolutionTitle" @dismiss="dismiss">
    {{
      __(
        'The vulnerability is no longer detected. Verify the vulnerability has been remediated before changing its status.',
      )
    }}
  </gl-alert>
</template>
