<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import { DOCUMENTATION_SOURCE_TYPES } from '../constants';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    sources: {
      type: Array,
      required: true,
    },
  },
  computed: {
    sourceLabel() {
      return n__('AI|Source', 'AI|Sources', this.sources.length || 0);
    },
  },
  methods: {
    getSourceIcon(sourceType) {
      const currentSourceType = Object.values(DOCUMENTATION_SOURCE_TYPES).find(
        ({ value }) => value === sourceType,
      );

      return currentSourceType?.icon || 'document';
    },
    getSourceTitle({ title, source_type: sourceType, stage, group, date, author }) {
      if (title) {
        return title;
      }

      if (sourceType === DOCUMENTATION_SOURCE_TYPES.DOC.value) {
        if (stage && group) {
          return `${stage} / ${group}`;
        }
      }

      if (sourceType === DOCUMENTATION_SOURCE_TYPES.BLOG.value) {
        if (date && author) {
          return `${date} / ${author}`;
        }
      }

      return __('Source');
    },
  },
};
</script>
<template>
  <div class="gl-mt-4 gl-mr-3 gl-text-gray-600" data-testid="tanuki-bot-chat-message-sources">
    <span>{{ sourceLabel }}:</span>

    <ul class="gl-list-style-none gl-p-0 gl-m-0">
      <li
        v-for="(source, index) in sources"
        :key="index"
        class="gl-display-flex gl-pt-3"
        data-testid="source-list-item"
      >
        <gl-icon
          v-if="source.source_type"
          :name="getSourceIcon(source.source_type)"
          class="gl-flex-shrink-0 gl-mr-2"
        />
        <gl-link :href="source.source_url">{{ getSourceTitle(source) }}</gl-link>
      </li>
    </ul>
  </div>
</template>
