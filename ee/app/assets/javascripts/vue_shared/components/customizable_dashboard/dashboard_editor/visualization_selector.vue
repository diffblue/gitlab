<script>
import { GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';
import { I18N_VISUALIZATION_SELECTOR_NEW } from '../constants';
import { availableVisualizationsValidator } from '../utils';

export default {
  name: 'VisualizationSelector',
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    availableVisualizations: {
      type: Object,
      required: true,
      validator: availableVisualizationsValidator,
    },
  },
  methods: {
    onAddClicked() {
      this.$emit('create');
    },
    selectVisualization(id, source) {
      this.$emit('select', id, source);
    },
    getVisualizationTitle(id) {
      return humanize(id);
    },
  },
  i18n: {
    I18N_VISUALIZATION_SELECTOR_NEW,
  },
};
</script>

<template>
  <div>
    <div class="gl-border-b-solid gl-border-1 gl-border-gray-100">
      <div v-for="(dataSource, title) in availableVisualizations" :key="title">
        <div class="gl-text-gray-900 gl-font-weight-bold gl-mb-4">
          {{ title }}
        </div>
        <gl-loading-icon v-if="dataSource.loading" size="md" class="gl-mb-4" />
        <ul v-else class="gl-p-0 gl-list-style-none gl-mb-2">
          <li
            v-for="(id, index) in dataSource.visualizationIds"
            :key="index"
            class="gl-display-flex gl-mb-3 gl-cursor-pointer gl-link gl-reset-color gl-hover-text-blue-600"
            tabindex="0"
            @click="selectVisualization(id, 'yml')"
            @keydown.enter="selectVisualization(id, 'yml')"
          >
            <gl-icon :size="24" class="flex-shrink-0 gl-mr-2" name="chart" />
            <span class="gl-align-items-center">
              {{ getVisualizationTitle(id) }}
            </span>
          </li>
        </ul>
      </div>
      <gl-button variant="confirm" category="tertiary" block @click="onAddClicked()">{{
        $options.i18n.I18N_VISUALIZATION_SELECTOR_NEW
      }}</gl-button>
    </div>
  </div>
</template>
