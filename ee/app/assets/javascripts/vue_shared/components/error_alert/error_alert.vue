<script>
import { GlAlert } from '@gitlab/ui';
import { generateHelpTextWithLinks, mapSystemToFriendlyError } from '~/lib/utils/error_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'ErrorAlert',
  components: { GlAlert },
  directives: {
    SafeHtml,
  },
  props: {
    error: {
      type: [Error, String],
      required: false,
      default: null,
    },
    errorDictionary: {
      type: Object,
      required: false,
      default: () => {},
    },
    defaultError: {
      type: Object,
      required: false,
      default: () => {},
    },
    dismissible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    friendlyError() {
      return mapSystemToFriendlyError(this.error, this.errorDictionary, this.defaultError);
    },
    friendlyErrorMessage() {
      return generateHelpTextWithLinks(this.friendlyError);
    },
  },
};
</script>
<template>
  <gl-alert
    v-if="error"
    variant="danger"
    :title="friendlyError.title"
    :dismissible="dismissible"
    @dismiss="$emit('dismiss')"
  >
    <span v-safe-html="friendlyErrorMessage"></span>
  </gl-alert>
</template>
