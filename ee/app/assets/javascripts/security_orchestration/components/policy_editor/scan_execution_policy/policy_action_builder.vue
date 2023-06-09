<script>
import {
  GlCollapsibleListbox,
  GlFormGroup,
  GlIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import GenericBaseLayoutComponent from '../generic_base_layout_component.vue';
import { ACTION_AND_LABEL, RULE_MODE_SCANNERS } from '../constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  DEFAULT_SCANNER,
  SCANNER_DAST,
  SCANNER_HUMANIZED_TEMPLATE,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
} from './constants';
import ProjectDastProfileSelector from './project_dast_profile_selector.vue';
import GroupDastProfileSelector from './group_dast_profile_selector.vue';
import RunnerTagsList from './runner_tags_list.vue';
import { buildScannerAction } from './lib';

export default {
  ACTION_AND_LABEL,
  SCANNERS: RULE_MODE_SCANNERS,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    GlIcon,
    GlSprintf,
    GenericBaseLayoutComponent,
    RunnerTagsList,
    ProjectDastProfileSelector,
    GroupDastProfileSelector,
  },
  directives: {
    GlTooltip,
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
    actionMessage() {
      return this.selectedScanner === SCANNER_DAST
        ? DAST_HUMANIZED_TEMPLATE
        : SCANNER_HUMANIZED_TEMPLATE;
    },
    selectedScannerText() {
      return RULE_MODE_SCANNERS[this.selectedScanner];
    },
    isFirstAction() {
      return this.actionIndex === 0;
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
    tags: {
      get() {
        return this.initAction.tags || [];
      },
      set(values) {
        this.$emit('changed', { ...this.initAction, tags: values });
      },
    },
  },
  methods: {
    setSelectedScanner({
      scanner = this.selectedScanner,
      siteProfile = this.siteProfile,
      scannerProfile = this.scannerProfile,
    }) {
      if (scanner !== this.selectedScanner) {
        this.selectedScanner = scanner;
      }

      this.$emit(
        'changed',
        buildScannerAction({
          scanner,
          siteProfile,
          scannerProfile,
        }),
      );
    },
  },
  i18n: {
    selectedTagsInformation: s__(
      'ScanExecutionPolicy|If the field is empty, the runner will be automatically selected',
    ),
    scannersHeaderText: s__('ScanExecutionPolicy|Select a scanner'),
    tags: s__('ScanExecutionPolicy|Tags'),
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
    <generic-base-layout-component :show-remove-button="false" @changed="$emit('changed', $event)">
      <template #content>
        <generic-base-layout-component class="gl-w-full gl-bg-white!" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="actionMessage">
              <template #scan>
                <gl-collapsible-listbox
                  :items="actionScannerList"
                  :header-text="$options.i18n.scannersHeaderText"
                  :selected="selectedScanner"
                  :toggle-text="selectedScannerText"
                  @select="setSelectedScanner({ scanner: $event })"
                />
              </template>
              <template #dastProfiles>
                <project-dast-profile-selector
                  v-if="isProject"
                  :full-path="namespacePath"
                  :saved-scanner-profile-name="scannerProfile"
                  :saved-site-profile-name="siteProfile"
                  @error="
                    $emit('parsing-error', $options.POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY)
                  "
                  @profiles-selected="setSelectedScanner"
                />
                <group-dast-profile-selector
                  v-else
                  :saved-scanner-profile-name="scannerProfile"
                  :saved-site-profile-name="siteProfile"
                  @set-profile="setSelectedScanner"
                />
              </template>

              <template #tags>
                <gl-form-group
                  class="gl-mb-0"
                  :label="$options.i18n.tags"
                  label-for="policy-tags"
                  label-sr-only
                >
                  <div class="gl-display-flex gl-align-items-center">
                    <runner-tags-list
                      v-model="tags"
                      :namespace-path="namespacePath"
                      :namespace-type="namespaceType"
                      @error="$emit('parsing-error', $options.POLICY_ACTION_BUILDER_TAGS_ERROR_KEY)"
                    />
                    <gl-icon
                      v-gl-tooltip
                      name="question-o"
                      :title="$options.i18n.selectedTagsInformation"
                      class="gl-text-blue-600 gl-ml-2"
                    />
                  </div>
                </gl-form-group>
              </template>
            </gl-sprintf>
          </template>
        </generic-base-layout-component>
      </template>
    </generic-base-layout-component>
  </div>
</template>
