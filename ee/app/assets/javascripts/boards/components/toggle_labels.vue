<script>
import { GlToggle } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

export default {
  components: {
    GlToggle,
    LocalStorageSync,
  },
  computed: {
    ...mapState(['isShowingLabels']),
    trackProperty() {
      return this.isShowingLabels ? 'on' : 'off';
    },
  },
  methods: {
    ...mapActions(['setShowLabels']),
    onToggle(val) {
      this.setShowLabels(val);
    },
  },
};
</script>

<template>
  <div class="board-labels-toggle-wrapper gl-display-flex gl-align-items-center gl-ml-3 gl-h-7">
    <local-storage-sync
      :value="isShowingLabels"
      storage-key="gl-show-board-labels"
      @input="setShowLabels"
    />
    <gl-toggle
      :value="isShowingLabels"
      :label="__('Show labels')"
      :data-track-property="trackProperty"
      data-track-action="toggle"
      data-track-label="show_labels"
      label-position="left"
      aria-describedby="board-labels-toggle-text"
      data-qa-selector="show_labels_toggle"
      class="gl-flex-direction-row"
      @change="onToggle"
    />
  </div>
</template>
