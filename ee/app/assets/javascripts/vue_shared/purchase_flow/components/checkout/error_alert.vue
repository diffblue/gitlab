<script>
import { GlAlert } from '@gitlab/ui';
import {
  generateHelpTextWithLinks,
  mapSystemToFriendlyError,
} from 'ee/vue_shared/purchase_flow/utils/purchase_errors';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'PurchaseErrorAlert',
  components: { GlAlert },
  directives: {
    SafeHtml,
  },
  props: {
    error: {
      type: Error,
      required: false,
      default: null,
    },
  },
  computed: {
    friendlyError() {
      return mapSystemToFriendlyError(this.error);
    },
    friendlyErrorMessage() {
      return generateHelpTextWithLinks(this.friendlyError);
    },
  },
};
</script>
<template>
  <gl-alert v-if="error" variant="danger" :dismissible="false">
    <span v-safe-html="friendlyErrorMessage"></span>
  </gl-alert>
</template>
