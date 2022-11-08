import Vue from 'vue';
import { mountEpicDropdown, mountIterationDropdown } from 'ee/sidebar/mount_sidebar';
import { initForm as initFormCE } from '~/issues';
import RelatedFeatureFlags from './components/related_feature_flags.vue';
import UnableToLinkVulnerabilityError from './components/unable_to_link_vulnerability_error.vue';

export function initForm() {
  mountEpicDropdown();
  mountIterationDropdown();
  initFormCE();
}

export function initRelatedFeatureFlags() {
  const el = document.querySelector('#js-related-feature-flags-root');

  if (!el) {
    return undefined;
  }

  return new Vue({
    el,
    name: 'RelatedFeatureFlagsRoot',
    provide: { endpoint: el.dataset.endpoint },
    render: (createElement) => createElement(RelatedFeatureFlags),
  });
}

export function initUnableToLinkVulnerabilityError() {
  const el = document.querySelector('#js-unable-to-link-vulnerability');

  if (!el) {
    return undefined;
  }

  const { vulnerabilityLink } = el.dataset;

  return new Vue({
    el,
    name: 'UnableToLinkVulnerabilityErrorRoot',
    render: (createElement) =>
      createElement(UnableToLinkVulnerabilityError, { props: { vulnerabilityLink } }),
  });
}
