<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlForm,
  GlFormGroup,
  GlIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { ACTION_THEN_LABEL, ACTION_AND_LABEL, RULE_MODE_SCANNERS } from '../constants';
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
  SCANNERS: RULE_MODE_SCANNERS,
  POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlForm,
    GlFormGroup,
    GlIcon,
    GlSprintf,
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
    actionLabel() {
      return this.actionIndex === 0 ? ACTION_THEN_LABEL : ACTION_AND_LABEL;
    },
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
  },
};
</script>

<template>
  <div class="security-policies-bg-gray-10 gl-rounded-base gl-p-5 gl-display-flex gl-relative">
    <gl-form
      class="gl-display-flex gl-flex-wrap gl-align-items-center gl-flex-grow-1 gl-gap-3"
      @submit.prevent
    >
      <gl-sprintf :message="actionMessage">
        <template #thenLabel>
          <label class="text-uppercase gl-font-lg gl-mb-0" data-testid="action-component-label">
            {{ actionLabel }}
          </label>
        </template>

        <template #scan>
          <gl-collapsible-listbox
            :items="actionScannerList"
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
            @error="$emit('parsing-error', $options.POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY)"
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
            :label="s__('ScanExecutionPolicy|Tags')"
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
    </gl-form>
    <div class="gl-min-w-7">
      <gl-button
        icon="remove"
        category="tertiary"
        :aria-label="__('Remove')"
        @click="$emit('remove', $event)"
      />
    </div>
  </div>
</template>
