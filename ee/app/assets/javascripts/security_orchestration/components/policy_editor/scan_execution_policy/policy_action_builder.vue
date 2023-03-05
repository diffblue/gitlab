<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTION_THEN_LABEL, ACTION_AND_LABEL, RULE_MODE_SCANNERS } from '../constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  DEFAULT_SCANNER,
  SCANNER_DAST,
  SCANNER_HUMANIZED_TEMPLATE,
} from './constants';
import RunnerTagsList from './runner_tags_list.vue';
import { buildScannerAction } from './lib';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlSprintf,
    RunnerTagsList,
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
    siteProfile: {
      get() {
        return this.initAction.site_profile?.trim() ?? '';
      },
      set(value) {
        this.setSelectedScanner({ siteProfile: value });
      },
    },
    scannerProfile: {
      get() {
        return this.initAction.scanner_profile?.trim() ?? '';
      },
      set(value) {
        this.setSelectedScanner({ scannerProfile: value });
      },
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
    selectedScannerProfilePlaceholder: s__('ScanExecutionPolicy|Select scanner profile'),
    selectedSiteProfilePlaceholder: s__('ScanExecutionPolicy|Select site profile'),
    selectedTagsInformation: s__(
      'ScanExecutionPolicy|If the field is empty, the runner will be automatically selected',
    ),
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-display-flex gl-relative">
    <gl-form inline class="gl-flex-grow-1 gl-gap-3" @submit.prevent>
      <gl-sprintf :message="actionMessage">
        <template #thenLabel>
          <label class="text-uppercase gl-font-lg" data-testid="action-component-label">
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

        <template #scannerProfile>
          <gl-form-group
            :label="s__('ScanExecutionPolicy|Scanner profile')"
            label-for="scanner-profile"
            label-sr-only
          >
            <gl-form-input
              id="scanner-profile"
              v-model="scannerProfile"
              :placeholder="$options.i18n.selectedScannerProfilePlaceholder"
              data-testid="scan-profile-selection"
            />
          </gl-form-group>
        </template>
        <template #siteProfile>
          <gl-form-group
            :label="s__('ScanExecutionPolicy|Site profile')"
            label-for="site-profile"
            label-sr-only
          >
            <gl-form-input
              id="site-profile"
              v-model="siteProfile"
              :placeholder="$options.i18n.selectedSiteProfilePlaceholder"
              data-testid="site-profile-selection"
            />
          </gl-form-group>
        </template>

        <template #tags>
          <gl-form-group
            :label="s__('ScanExecutionPolicy|Tags')"
            label-for="policy-tags"
            label-sr-only
          >
            <div class="gl-display-flex gl-align-items-center">
              <runner-tags-list
                v-model="tags"
                :namespace-path="namespacePath"
                :namespace-type="namespaceType"
                @error="$emit('parsing-error')"
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
