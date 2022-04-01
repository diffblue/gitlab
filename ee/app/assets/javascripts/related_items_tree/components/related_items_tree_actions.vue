<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { mapState } from 'vuex';

import { ITEM_TABS } from '../constants';
import ToggleLabels from '../../boards/components/toggle_labels.vue';

export default {
  ITEM_TABS,
  components: {
    GlButtonGroup,
    GlButton,
    ToggleLabels,
  },
  props: {
    activeTab: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['allowSubEpics']),
  },
};
</script>

<template>
  <div class="card-header d-flex gl-px-5 gl-pt-4 gl-pt-3 flex-column flex-sm-row border-bottom-0">
    <div>
      <gl-button-group data-testid="buttons" class="gl-flex-grow-1 gl-display-flex">
        <gl-button
          class="js-epic-tree-tab"
          data-testid="tree-view-button"
          :selected="activeTab === $options.ITEM_TABS.TREE"
          @click="() => $emit('tab-change', this.$options.ITEM_TABS.TREE)"
        >
          {{ __('Tree view') }}
        </gl-button>
        <gl-button
          v-if="allowSubEpics"
          class="js-epic-roadmap-tab"
          data-testid="roadmap-view-button"
          :selected="activeTab === $options.ITEM_TABS.ROADMAP"
          @click="() => $emit('tab-change', this.$options.ITEM_TABS.ROADMAP)"
        >
          {{ __('Roadmap view') }}
        </gl-button>
      </gl-button-group>
    </div>
    <div class="ml-auto gl-display-none gl-sm-display-flex">
      <!-- empty -->
    </div>
    <div
      v-if="activeTab === $options.ITEM_TABS.TREE"
      class="gl-sm-display-inline-flex gl-display-flex gl-mt-3 gl-sm-mt-0"
    >
      <toggle-labels class="gl-sm-ml-3! gl-ml-0!" />
    </div>
  </div>
</template>
