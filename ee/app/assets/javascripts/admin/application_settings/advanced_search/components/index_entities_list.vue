<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    entities: {
      type: Array,
      required: false,
      default: () => [],
    },
    emptyText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="index-entities-list gl-border gl-rounded-small gl-overflow-auto gl-bg-white">
    <ul v-if="entities.length" class="gl-list-style-none gl-p-0 gl-my-2">
      <li v-for="entity in entities" :key="entity.id" class="gl-px-5 gl-py-2">
        <div class="gl-display-flex gl-align-items-center">
          <div class="gl-flex-grow-1 gl-pr-3 gl-truncate-end">{{ entity.text }}</div>
          <gl-button
            variant="danger"
            category="secondary"
            icon="remove"
            data-testid="remove-index-entity"
            @click="$emit('remove', entity.id)"
          />
        </div>
      </li>
    </ul>
    <div v-else class="gl-h-full gl-display-flex gl--flex-center">
      {{ emptyText }}
    </div>
  </div>
</template>
