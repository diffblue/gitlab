<script>
import shieldCheckIllustration from '@gitlab/svgs/dist/illustrations/secure-sm.svg';
import magnifyingGlassIllustration from '@gitlab/svgs/dist/illustrations/search-sm.svg';
import { GlCard, GlButton } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __ } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';

const i18n = {
  cancel: __('Cancel'),
  examples: __('Examples'),
  selectPolicy: s__('SecurityOrchestration|Select policy'),
  scanResultPolicyTitle: s__('SecurityOrchestration|Scan result policy'),
  scanResultPolicyDesc: s__(
    'SecurityOrchestration|Use a scan result policy to create rules that check for security vulnerabilities and license compliance before merging a merge request.',
  ),
  scanResultPolicyExample: s__(
    'SecurityOrchestration|If any scanner finds a newly detected critical vulnerability in an open merge request targeting the master branch, then require two approvals from any member of App security.',
  ),
  scanExecutionPolicyTitle: s__('SecurityOrchestration|Scan execution policy'),
  scanExecutionPolicyDesc: s__(
    'SecurityOrchestration|Use a scan execution policy to create rules which enforce security scans for particular branches at a certain time. Supported types are SAST, SAST IaC, DAST, Secret detection, Container scanning, and Dependency scanning.',
  ),
  scanExecutionPolicyExample: s__(
    'SecurityOrchestration|Run a DAST scan with Scan Profile A and Site Profile A when a pipeline run against the main branch.',
  ),
};

export default {
  components: {
    GlCard,
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['policiesPath'],
  computed: {
    policies() {
      return [
        {
          urlParameter: POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter,
          title: i18n.scanResultPolicyTitle,
          description: i18n.scanResultPolicyDesc,
          example: i18n.scanResultPolicyExample,
          svg: shieldCheckIllustration,
        },
        {
          urlParameter: POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter,
          title: i18n.scanExecutionPolicyTitle,
          description: i18n.scanExecutionPolicyDesc,
          example: i18n.scanExecutionPolicyExample,
          svg: magnifyingGlassIllustration,
        },
      ];
    },
  },
  methods: {
    constructUrl(policyType) {
      return mergeUrlParams({ type: policyType }, window.location.href);
    },
  },
  i18n,
  safeHtmlConfig: { ADD_TAGS: ['use'] },
};
</script>
<template>
  <div class="gl-mb-4">
    <div
      class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-6 gl-mb-4"
      data-qa-selector="policy_selection_wizard"
    >
      <gl-card
        v-for="option in policies"
        :key="option.title"
        body-class="gl-p-6 gl-display-flex gl-flex-grow-1"
      >
        <div class="gl-mr-6 gl-text-white">
          <div v-safe-html:[$options.safeHtmlConfig]="option.svg"></div>
        </div>
        <div class="gl-display-flex gl-flex-direction-column">
          <h4 class="gl-mt-0">{{ option.title }}</h4>
          <p>{{ option.description }}</p>
          <h5>{{ $options.i18n.examples }}</h5>
          <p class="gl-flex-grow-1">{{ option.example }}</p>
          <div>
            <gl-button
              variant="confirm"
              :href="constructUrl(option.urlParameter)"
              :data-testid="`select-policy-${option.urlParameter}`"
              >{{ $options.i18n.selectPolicy }}</gl-button
            >
          </div>
        </div>
      </gl-card>
    </div>
    <gl-button :href="policiesPath" data-testid="back-button">{{ $options.i18n.cancel }}</gl-button>
  </div>
</template>
