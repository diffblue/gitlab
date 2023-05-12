<script>
import { marked } from 'marked';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { sanitize } from '~/lib/dompurify';
import { markdownConfig } from '~/lib/utils/text_utility';
import { __ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    CodeBlockHighlighted,
    ModalCopyButton,
  },
  directives: {
    SafeHtml,
  },
  props: {
    markdown: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hoverMap: {},
    };
  },
  computed: {
    markdownBlocks() {
      // we use lexer https://marked.js.org/using_pro#lexer
      // to get an array of tokens that marked npm module uses.
      // We will use these tokens to override rendering of some of them
      // with our vue components
      const tokens = marked.lexer(this.markdown);
      return tokens;
    },
  },
  methods: {
    getSafeHtml(markdown) {
      return sanitize(marked.parse(markdown), markdownConfig);
    },
    setHoverOn(key) {
      this.hoverMap = { ...this.hoverMap, [key]: true };
    },
    setHoverOff(key) {
      this.hoverMap = { ...this.hoverMap, [key]: false };
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
  i18n: {
    copyCodeTitle: __('Copy code'),
  },
};
</script>
<template>
  <div>
    <template v-for="(block, index) in markdownBlocks">
      <div
        v-if="block.type === 'code'"
        :key="`${block.type}-${index}`"
        class="gl-relative gl-mb-4"
        data-testid="code-block-wrapper"
        @mouseenter="() => setHoverOn(`${block.type}-${index}`)"
        @mouseleave="() => setHoverOff(`${block.type}-${index}`)"
      >
        <modal-copy-button
          v-if="hoverMap[`${block.type}-${index}`] === true"
          :title="$options.i18n.copyCodeTitle"
          :text="block.text"
          class="gl-absolute gl-top-4 gl-right-4 gl-z-index-1 gl-transition-duration-medium"
        />
        <code-block-highlighted
          class="gl-border gl-rounded-0! gl-p-4 gl-mb-0 gl-overflow-y-auto"
          :language="block.lang"
          :code="block.text"
        />
      </div>
      <div
        v-else
        :key="`text-${index}`"
        v-safe-html:[$options.safeHtmlConfig]="getSafeHtml(block.raw)"
        class="gl-mb-4"
        data-testid="non-code-markdown"
      ></div>
    </template>
  </div>
</template>
