<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getMarkdown } from '~/rest_api';

export default {
  components: { GlSkeletonLoader },
  directives: {
    SafeHtml,
  },
  inheritAttrs: false,
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      markdown: '',
      loading: true,
      error: false,
    };
  },
  mounted() {
    this.renderMarkdown();
  },
  methods: {
    async renderMarkdown() {
      this.loading = true;

      try {
        const { data } = await getMarkdown({ text: this.value, gfm: true });
        this.markdown = data.html;
      } catch (e) {
        Sentry.captureException(e);
        this.error = true;
      }

      this.loading = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-skeleton-loader v-if="loading" :width="200" :lines="2" />
    <div v-if="markdown" v-safe-html="markdown" data-testid="markdown"></div>
  </div>
</template>
