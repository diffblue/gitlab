import { spriteIcon } from '~/lib/utils/common_utils';
import { sprintf, s__ } from '~/locale';

// Securely open external links in a new tab.
function getLinkStartTag(url) {
  return `<a href="${url}" target="_blank" rel="noopener noreferrer">`;
}

// Add in the external link icon at the end of every link.
const linkEndTag = `${spriteIcon('external-link', 's16')}</a>`;

export default {
  computed: {
    sastPopover() {
      return {
        title: s__(
          'ciReport|Static Application Security Testing (SAST) detects known vulnerabilities in your source code.',
        ),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about SAST %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.sastHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    containerScanningPopover() {
      return {
        title: s__(
          'ciReport|Container scanning detects known vulnerabilities in your docker images.',
        ),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about Container Scanning %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.containerScanningHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    dastPopover() {
      return {
        title: s__(
          'ciReport|Dynamic Application Security Testing (DAST) detects known vulnerabilities in your web application.',
        ),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about DAST %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.dastHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    dependencyScanningPopover() {
      return {
        title: s__(
          "ciReport|Dependency Scanning detects known vulnerabilities in your source code's dependencies.",
        ),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about Dependency Scanning %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.dependencyScanningHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    secretDetectionPopover() {
      return {
        title: s__(
          'ciReport|Secret Detection detects secrets and credentials vulnerabilities in your source code.',
        ),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about Secret Detection %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.secretDetectionHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    coverageFuzzingPopover() {
      return {
        title: s__('ciReport|Coverage Fuzzing'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about Coverage Fuzzing %{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.coverageFuzzingHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
    apiFuzzingPopover() {
      return {
        title: s__('ciReport|API Fuzzing'),
        content: sprintf(
          s__('ciReport|%{linkStartTag}Learn more about API Fuzzing%{linkEndTag}'),
          {
            linkStartTag: getLinkStartTag(this.apiFuzzingHelpPath),
            linkEndTag,
          },
          false,
        ),
      };
    },
  },
};
