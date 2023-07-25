<script>
import { isEmpty } from 'lodash';
import { GlCollapsibleListbox, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import GenericBaseLayoutComponent from '../generic_base_layout_component.vue';
import { ACTION_AND_LABEL, RULE_MODE_SCANNERS } from '../constants';
import ScanFilterSelector from '../scan_filter_selector.vue';
import { CI_VARIABLE, RUNNER_TAGS, FILTERS } from './scan_filters/constants';
import CiVariablesSelectors from './scan_filters/ci_variables_selectors.vue';
import GroupDastProfileSelector from './scan_filters/group_dast_profile_selector.vue';
import ProjectDastProfileSelector from './scan_filters/project_dast_profile_selector.vue';
import RunnerTagsFilter from './scan_filters/runner_tags_filter.vue';
import {
  DEFAULT_SCANNER,
  SCANNER_DAST,
  SCANNER_HUMANIZED_TEMPLATE,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
} from './constants';
import { buildScannerAction } from './lib';

export default {
  ACTION_AND_LABEL,
  CI_VARIABLE,
  FILTERS,
  SCANNERS: RULE_MODE_SCANNERS,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  components: {
    GlCollapsibleListbox,
    GlSprintf,
    GenericBaseLayoutComponent,
    CiVariablesSelectors,
    ProjectDastProfileSelector,
    GroupDastProfileSelector,
    RunnerTagsFilter,
    ScanFilterSelector,
  },
  inject: ['namespacePath', 'namespaceType'],
  props: {
    initAction: {
      type: Object,
      required: true,
    },
    actionIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      filters: {
        [RUNNER_TAGS]: this.initAction?.tags?.length ? [] : null,
        [CI_VARIABLE]: null,
      },
      selectedScanner: this.initAction.scan || DEFAULT_SCANNER,
    };
  },
  computed: {
    actionScannerList() {
      return Object.entries(RULE_MODE_SCANNERS).map(([value, text]) => ({
        value,
        text,
      }));
    },
    ciVariables() {
      return this.initAction.variables || {};
    },
    isCIVariableSelectorSelected() {
      return (
        this.isFilterSelected(this.$options.CI_VARIABLE) || Object.keys(this.ciVariables).length > 0
      );
    },
    isDast() {
      return this.selectedScanner === SCANNER_DAST;
    },
    isRunnerTagFilterSelected() {
      return this.isFilterSelected(RUNNER_TAGS) || this.tags.length > 0;
    },
    selectedScannerText() {
      return RULE_MODE_SCANNERS[this.selectedScanner];
    },
    isFirstAction() {
      return this.actionIndex === 0;
    },
    isGroup() {
      return this.namespaceType === NAMESPACE_TYPES.GROUP;
    },
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    siteProfile() {
      return this.initAction.site_profile?.trim() ?? '';
    },
    scannerProfile() {
      return this.initAction.scanner_profile?.trim() ?? '';
    },
    tags() {
      return this.initAction.tags || [];
    },
  },
  methods: {
    isFilterSelected(filter) {
      return Boolean(this.filters[filter]);
    },
    emitCiVariableFilterChanges() {
      const updatedAction = { ...this.initAction };
      delete updatedAction.variables;
      this.$emit('changed', updatedAction);
    },
    emitRunnerTagsFilterChanges() {
      const updatedAction = { ...this.initAction, tags: [] };
      this.$emit('changed', updatedAction);
    },
    removeCiFilter() {
      const newFilters = { ...this.filters };
      delete newFilters[CI_VARIABLE];
      this.filters = newFilters;
      this.emitCiVariableFilterChanges();
    },
    removeRunnerFilter() {
      const newFilters = { ...this.filters };
      delete newFilters[RUNNER_TAGS];
      this.filters = newFilters;
      this.emitRunnerTagsFilterChanges();
    },
    selectFilter(filter) {
      this.$set(this.filters, filter, []);
      if (filter === RUNNER_TAGS) {
        this.triggerChanged({ tags: [] });
      }
      if (filter === CI_VARIABLE) {
        this.triggerChanged({ variables: { '': '' } });
      }
    },
    setSelectedScanner({
      scanner = this.selectedScanner,
      siteProfile = this.siteProfile,
      scannerProfile = this.scannerProfile,
    }) {
      const updatedAction = buildScannerAction({
        scanner,
        siteProfile,
        scannerProfile,
      });

      const { tags, variables } = this.initAction;
      updatedAction.tags = [...tags];
      if (scanner !== this.selectedScanner) {
        this.selectedScanner = scanner;
        this.filters = {};
      } else if (!isEmpty(variables)) {
        updatedAction.variables = { ...variables };
      }

      this.$emit('changed', updatedAction);
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initAction, ...value });
    },
  },
  i18n: {
    scannersHeaderText: s__('ScanExecutionPolicy|Select a scanner'),
    scannerHumanizedTemplate: SCANNER_HUMANIZED_TEMPLATE,
  },
};
</script>

<template>
  <div>
    <div
      v-if="!isFirstAction"
      class="gl-text-gray-500 gl-mb-4 gl-ml-5"
      data-testid="action-and-label"
    >
      {{ $options.ACTION_AND_LABEL }}
    </div>
    <generic-base-layout-component class="gl-pb-0" :show-remove-button="false">
      <template #content>
        <generic-base-layout-component class="gl-w-full gl-bg-white" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="$options.i18n.scannerHumanizedTemplate">
              <template #scan>
                <gl-collapsible-listbox
                  :items="actionScannerList"
                  :header-text="$options.i18n.scannersHeaderText"
                  :selected="selectedScanner"
                  :toggle-text="selectedScannerText"
                  @select="setSelectedScanner({ scanner: $event })"
                />
              </template>
            </gl-sprintf>
          </template>
        </generic-base-layout-component>
      </template>
    </generic-base-layout-component>
    <generic-base-layout-component class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <project-dast-profile-selector
          v-if="isProject && isDast"
          :full-path="namespacePath"
          :saved-scanner-profile-name="scannerProfile"
          :saved-site-profile-name="siteProfile"
          @error="$emit('parsing-error', $options.POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY)"
          @profiles-selected="setSelectedScanner"
        />

        <group-dast-profile-selector
          v-if="isGroup && isDast"
          :saved-scanner-profile-name="scannerProfile"
          :saved-site-profile-name="siteProfile"
          @set-profile="setSelectedScanner"
        />

        <runner-tags-filter
          v-if="isRunnerTagFilterSelected"
          :selected="tags"
          @remove="removeRunnerFilter"
          @input="triggerChanged"
          @error="$emit('parsing-error', $options.POLICY_ACTION_BUILDER_TAGS_ERROR_KEY)"
        />

        <ci-variables-selectors
          v-if="isCIVariableSelectorSelected"
          class="gl-bg-white"
          :scan-type="initAction.scan"
          :selected="initAction.variables"
          @remove="removeCiFilter"
          @input="triggerChanged"
        />

        <scan-filter-selector
          class="gl-w-full gl-bg-white"
          :filters="$options.FILTERS"
          :selected="filters"
          @select="selectFilter"
        />
      </template>
    </generic-base-layout-component>
  </div>
</template>
