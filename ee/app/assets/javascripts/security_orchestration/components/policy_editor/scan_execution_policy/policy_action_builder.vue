<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlIcon,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ACTION_THEN_LABEL, ACTION_AND_LABEL } from '../constants';
import {
  DAST_HUMANIZED_TEMPLATE,
  DAST_HUMANIZED_TEMPLATE_WITH_TAGS,
  DEFAULT_SCANNER,
  SCANNER_DAST,
  SCANNER_HUMANIZED_TEMPLATE,
  SCANNER_HUMANIZED_TEMPLATE_WITH_TAGS,
  RULE_MODE_SCANNERS,
} from './constants';
import { buildScannerAction } from './lib';

export default {
  SCANNERS: RULE_MODE_SCANNERS,
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
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
    actionMessage() {
      if (this.selectedScanner === SCANNER_DAST) {
        return this.glFeatures.scanExecutionTags
          ? DAST_HUMANIZED_TEMPLATE_WITH_TAGS
          : DAST_HUMANIZED_TEMPLATE;
      }

      return this.glFeatures.scanExecutionTags
        ? SCANNER_HUMANIZED_TEMPLATE_WITH_TAGS
        : SCANNER_HUMANIZED_TEMPLATE;
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
        return this.initAction.tags?.join(',').trim() ?? '';
      },
      set(values) {
        const tags = values.split(',');
        this.$emit('changed', { ...this.initAction, tags });
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
          includeTags: this.glFeatures.scanExecutionTags,
        }),
      );
    },
  },
  i18n: {
    selectedScannerProfilePlaceholder: s__('ScanExecutionPolicy|Select scanner profile'),
    selectedSiteProfilePlaceholder: s__('ScanExecutionPolicy|Select site profile'),
    selectedTagsPlaceholder: s__('ScanExecutionPolicy|Ex, tag-name-1, tag-name-2'),
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
          <gl-dropdown :text="$options.SCANNERS[selectedScanner]" data-testid="action-scanner-text">
            <gl-dropdown-item
              v-for="(value, key) in $options.SCANNERS"
              :key="key"
              @click="setSelectedScanner({ scanner: key })"
            >
              {{ value }}
            </gl-dropdown-item>
          </gl-dropdown>
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
            <gl-form-input
              id="policy-tags"
              v-model="tags"
              :placeholder="$options.i18n.selectedTagsPlaceholder"
              data-testid="policy-tags-input"
            />
          </gl-form-group>
          <gl-icon
            v-gl-tooltip
            name="question-o"
            :title="$options.i18n.selectedTagsInformation"
            class="gl-text-blue-600"
          />
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
