<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { mapState } from 'vuex';

import ToggleLabels from 'ee/boards/components/toggle_labels.vue';
import { ITEM_TABS } from '../constants';

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
  <div
    class="card-header gl-display-flex gl-px-4 gl-py-3 gl-flex-direction-column gl-sm-flex-direction-row gl-border-bottom-0 gl-bg-gray-10"
  >
    <div>
      <gl-button-group
        v-if="allowSubEpics"
        data-testid="buttons"
        class="gl-flex-grow-1 gl-display-flex"
      >
        <gl-button
          class="js-epic-tree-tab"
          data-testid="tree-view-button"
          :selected="activeTab === $options.ITEM_TABS.TREE"
          @click="() => $emit('tab-change', $options.ITEM_TABS.TREE)"
        >
          {{ __('Tree view') }}
        </gl-button>
        <gl-button
          class="js-epic-roadmap-tab"
          data-testid="roadmap-view-button"
          :selected="activeTab === $options.ITEM_TABS.ROADMAP"
          @click="() => $emit('tab-change', $options.ITEM_TABS.ROADMAP)"
        >
          {{ __('Roadmap view') }}
        </gl-button>
      </gl-button-group>
    </div>
    <div
      v-if="activeTab === $options.ITEM_TABS.TREE"
      class="gl-sm-display-inline-flex gl-display-flex gl-mt-3 gl-sm-mt-0 gl-sm-ml-auto"
    >
      <toggle-labels class="gl-sm-ml-3! gl-ml-0!" />
    </div>
  </div>
</template>
