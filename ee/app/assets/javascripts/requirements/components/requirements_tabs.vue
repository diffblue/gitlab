<script>
import { GlBadge, GlButton, GlButtonGroup, GlTabs, GlTab, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { filterState } from '../constants';

export default {
  i18n: {
    exportAsCsvLabel: __('Export as CSV'),
    importRequirementsLabel: __('Import requirements'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  filterState,
  components: {
    GlBadge,
    GlButton,
    GlTabs,
    GlTab,
    GlButtonGroup,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
    },
    showCreateForm: {
      type: Boolean,
      required: true,
    },
    canCreateRequirement: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    isOpenTab() {
      return this.filterBy === filterState.opened;
    },
    isArchivedTab() {
      return this.filterBy === filterState.archived;
    },
    isAllTab() {
      return this.filterBy === filterState.all;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
    <gl-tabs content-class="gl-p-0">
      <gl-tab
        :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          'data-testid': 'state-opened',
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        :active="isOpenTab"
        @click="$emit('click-tab', { filterBy: $options.filterState.opened })"
      >
        <template #title>
          <span>{{ __('Open') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ requirementsCount.OPENED }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab
        :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          'data-testid': 'state-archived',
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        :active="isArchivedTab"
        @click="$emit('click-tab', { filterBy: $options.filterState.archived })"
      >
        <template #title>
          <span>{{ __('Archived') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{
            requirementsCount.ARCHIVED
          }}</gl-badge>
        </template>
      </gl-tab>
      <gl-tab
        :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          'data-testid': 'state-all',
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        :active="isAllTab"
        @click="$emit('click-tab', { filterBy: $options.filterState.all })"
      >
        <template #title>
          <span>{{ __('All') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ requirementsCount.ALL }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <div v-if="isOpenTab && canCreateRequirement" class="nav-controls">
      <gl-button-group>
        <gl-button
          v-gl-tooltip
          :title="$options.i18n.exportAsCsvLabel"
          :aria-label="$options.i18n.exportAsCsvLabel"
          category="secondary"
          :disabled="showCreateForm"
          icon="export"
          @click="$emit('click-export-requirements')"
        />
        <gl-button
          v-gl-tooltip
          :title="$options.i18n.importRequirementsLabel"
          :aria-label="$options.i18n.importRequirementsLabel"
          category="secondary"
          class="js-import-requirements"
          :disabled="showCreateForm"
          icon="import"
          @click="$emit('click-import-requirements')"
        />
      </gl-button-group>

      <gl-button
        category="primary"
        variant="confirm"
        class="js-new-requirement"
        :disabled="showCreateForm"
        @click="$emit('click-new-requirement')"
        >{{ __('New requirement') }}</gl-button
      >
    </div>
  </div>
</template>
