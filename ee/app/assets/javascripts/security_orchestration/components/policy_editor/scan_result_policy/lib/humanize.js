import { sprintf, s__, n__, __ } from '~/locale';
import {
  INVALID_RULE_MESSAGE,
  NO_RULE_MESSAGE,
  INVALID_PROTECTED_BRANCHES,
  BRANCH_TYPE_KEY,
  HUMANIZED_BRANCH_TYPE_TEXT_DICT,
  SCAN_RESULT_BRANCH_TYPE_OPTIONS,
  GREATER_THAN_OPERATOR,
  LESS_THAN_OPERATOR,
} from '../../constants';
import { createHumanizedScanners } from '../../utils';
import {
  NEEDS_TRIAGE_PLURAL,
  APPROVAL_VULNERABILITY_STATE_GROUPS,
  APPROVAL_VULNERABILITY_STATES_FLAT,
} from '../scan_filters/constants';
import { LICENSE_FINDING, LICENSE_STATES } from './rules';
import { groupSelectedVulnerabilityStates } from './vulnerability_states';

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Array} items strings representing items to compose the final sentence
 * @param {String} singular string to be used for single items
 * @param {Boolean} hasTextBeforeItems
 * @param {String} plural string to be used for multiple items
 * @returns {String}
 */
const humanizeItems = ({ items, singular, plural, hasTextBeforeItems = false }) => {
  if (!items) {
    return '';
  }

  let noun = '';

  if (singular && plural) {
    noun = items.length > 1 ? plural : singular;
  }

  const finalSentence = [];

  if (hasTextBeforeItems && noun) {
    finalSentence.push(`${noun} `);
  }

  if (items.length === 1) {
    finalSentence.push(items.join(','));
  } else {
    const lastItem = items.pop();
    finalSentence.push(items.join(', '), s__('SecurityOrchestration| or '), lastItem);
  }

  if (!hasTextBeforeItems && noun) {
    finalSentence.push(` ${noun}`);
  }

  return finalSentence.join('');
};

/**
 * Create a human-readable version of the branches
 * @param {Array} branches
 * @returns {String}
 */
const humanizeBranches = (branches = []) => {
  const hasNoBranch = branches.length === 0;

  if (hasNoBranch) {
    return s__('SecurityOrchestration|any protected branch');
  }

  return sprintf(s__('SecurityOrchestration|the %{branches}'), {
    branches: humanizeItems({
      items: branches,
      singular: s__('SecurityOrchestration|branch'),
      plural: s__('SecurityOrchestration|branches'),
    }),
  });
};

const humanizeBranchType = (branchType) => {
  return sprintf(s__('SecurityOrchestration|targeting %{branchTypeText}'), {
    branchTypeText: HUMANIZED_BRANCH_TYPE_TEXT_DICT[branchType],
  });
};

/**
 * Create a human-readable version of the allowed vulnerabilities
 * @param {Number} vulnerabilitiesAllowed
 * @returns {String}
 */
const humanizeVulnerabilitiesAllowed = (vulnerabilitiesAllowed) =>
  vulnerabilitiesAllowed
    ? sprintf(s__('SecurityOrchestration|more than %{allowed}'), {
        allowed: vulnerabilitiesAllowed,
      })
    : s__('SecurityOrchestration|any');

/**
 * Create a translation map for vulnerability statuses,
 * applying replacements needed for human-readable version of vulnerability states
 * @returns {Object}
 */
const vulnerabilityStatusTranslationMap = {
  ...APPROVAL_VULNERABILITY_STATES_FLAT,
  new_needs_triage: NEEDS_TRIAGE_PLURAL,
  detected: NEEDS_TRIAGE_PLURAL,
};

/**
 * Create a human-readable version of the vulnerability states
 * @param {Array} vulnerabilitiesStates
 * @returns {String}
 */
const humanizeVulnerabilityStates = (vulnerabilitiesStates) => {
  if (!vulnerabilitiesStates.length) {
    return '';
  }

  const divider = __(', or ');
  const statesByGroup = groupSelectedVulnerabilityStates(vulnerabilitiesStates);
  const stateGroups = Object.keys(statesByGroup);

  return stateGroups
    .reduce((sentence, stateGroup) => {
      return [
        ...sentence,
        sprintf(s__('SecurityOrchestration|%{state} and %{statuses}'), {
          state: APPROVAL_VULNERABILITY_STATE_GROUPS[stateGroup].toLowerCase(),
          statuses: humanizeItems({
            items: statesByGroup[stateGroup].map((status) =>
              vulnerabilityStatusTranslationMap[status].toLowerCase(),
            ),
          }),
        }),
      ];
    }, [])
    .join(divider);
};

/**
 * Create a human-readable version of vulnerability age
 * @param {Object} vulnerabilityAge
 * @returns {String}
 */
const humanizeVulnerabilityAge = (vulnerabilityAge) => {
  const { value, operator } = vulnerabilityAge;

  const strMap = {
    day: (number) => n__('%d day', '%d days', number),
    week: (number) => n__('%d week', '%d weeks', number),
    month: (number) => n__('%d month', '%d months', number),
    year: (number) => n__('%d year', '%d years', number),
  };

  const baseStr = {
    [GREATER_THAN_OPERATOR]: sprintf(
      s__('SecurityOrchestration|Vulnerability age is greater than %{vulnerabilityAge}.'),
      { vulnerabilityAge: strMap[vulnerabilityAge.interval](value) },
    ),
    [LESS_THAN_OPERATOR]: sprintf(
      s__('SecurityOrchestration|Vulnerability age is less than %{vulnerabilityAge}.'),
      { vulnerabilityAge: strMap[vulnerabilityAge.interval](value) },
    ),
  };

  return baseStr[operator];
};

/**
 * Create a human-readable version of the scanners
 * @param {Array} scanners
 * @returns {String}
 */
const humanizeScanners = (scanners) => {
  const hasEmptyScanners = scanners.length === 0;

  if (hasEmptyScanners) {
    return s__('SecurityOrchestration|any security scanner finds');
  }

  return sprintf(s__('SecurityOrchestration|%{scanners}'), {
    scanners: humanizeItems({
      items: scanners,
      singular: s__('SecurityOrchestration|scanner finds'),
      plural: s__('SecurityOrchestration|scanners find'),
    }),
  });
};

const humanizeLicenseDetection = (licenseStates) => {
  const maxNumOfLicenseStates = Object.entries(LICENSE_STATES).length;

  if (licenseStates.length === maxNumOfLicenseStates) {
    return '';
  }

  return sprintf(s__('SecurityOrchestration| that is %{licenseState} and is'), {
    licenseState: LICENSE_STATES[licenseStates[0]].toLowerCase(),
  });
};

const humanizeLicenses = (originalLicenses) => {
  const licenses = [...originalLicenses];

  if (licenses.length === 1) {
    return licenses[0];
  }

  const lastLicense = licenses.pop();
  return sprintf(s__('SecurityOrchestration|%{licenses} and %{lastLicense}'), {
    licenses: licenses.join(', '),
    lastLicense,
  });
};

const hasBranchType = (rule) => BRANCH_TYPE_KEY in rule;

const hasValidBranchType = (rule) => {
  if (!rule) return false;

  return (
    hasBranchType(rule) &&
    SCAN_RESULT_BRANCH_TYPE_OPTIONS()
      .map(({ value }) => value)
      .includes(rule.branch_type)
  );
};

/**
 * Create a human-readable version of the rule
 * @param {Object} rule {type: 'scan_finding', branch_type: 'protected', branches: ['master'], scanners: ['container_scanning'], vulnerabilities_allowed: 1, severity_levels: ['critical']}
 * @returns {Object} {summary: '', criteriaList: []}
 */
const humanizeRule = (rule) => {
  const humanizedValue = hasBranchType(rule)
    ? humanizeBranchType(rule.branch_type)
    : humanizeBranches(rule.branches);
  const targetingValue = hasBranchType(rule) ? '' : __('targeting ');

  if (hasBranchType(rule) && !hasValidBranchType(rule)) {
    return {
      summary: INVALID_RULE_MESSAGE,
    };
  }

  if (rule.type === LICENSE_FINDING) {
    const summaryText = rule.match_on_inclusion
      ? s__(
          'SecurityOrchestration|When license scanner finds any license matching %{licenses}%{detection} in an open merge request %{targeting}%{branches}.',
        )
      : s__(
          'SecurityOrchestration|When license scanner finds any license except %{licenses}%{detection} in an open merge request %{targeting}%{branches}.',
        );

    return {
      summary: sprintf(summaryText, {
        licenses: humanizeLicenses(rule.license_types),
        detection: humanizeLicenseDetection(rule.license_states),
        branches: humanizedValue,
        targeting: targetingValue,
      }),
    };
  }

  const criteriaList = [];

  const addCriteria = (predicate, compileCriteria) => {
    if (predicate) {
      criteriaList.push(compileCriteria());
    }
  };

  addCriteria(rule.severity_levels.length, () =>
    sprintf(s__('SecurityOrchestration|Severity is %{severity}.'), {
      severity: humanizeItems({
        items: rule.severity_levels,
      }),
    }),
  );

  addCriteria(rule.vulnerability_states.length, () =>
    sprintf(s__('SecurityOrchestration|Vulnerabilities are %{vulnerabilityStates}.'), {
      vulnerabilityStates: humanizeVulnerabilityStates(rule.vulnerability_states),
    }),
  );

  addCriteria(Object.keys(rule.vulnerability_age || {}).length, () =>
    humanizeVulnerabilityAge(rule.vulnerability_age),
  );

  return {
    summary: sprintf(
      s__(
        'SecurityOrchestration|When %{scanners} %{vulnerabilitiesAllowed} %{vulnerability} in an open merge request %{targeting}%{branches}%{criteriaApply}',
      ),
      {
        scanners: humanizeScanners(createHumanizedScanners(rule.scanners)),
        branches: humanizedValue,
        targeting: targetingValue,
        vulnerabilitiesAllowed: humanizeVulnerabilitiesAllowed(rule.vulnerabilities_allowed),
        vulnerability: n__('vulnerability', 'vulnerabilities', rule.vulnerabilities_allowed),
        criteriaApply: criteriaList.length
          ? s__('SecurityOrchestration| and all the following apply:')
          : '.',
      },
    ),
    criteriaList,
  };
};

/**
 * Create a human-readable version of the rules
 * @param {Array} rules [{type: 'scan_finding', branches: ['master'], scanners: ['container_scanning'], vulnerabilities_allowed: 1, severity_levels: ['critical']}]
 * @returns {Array} [{summary: '', criteriaList: []}]
 */
export const humanizeRules = (rules) => {
  const humanizedRules = rules.reduce((acc, curr) => {
    return [...acc, humanizeRule(curr)];
  }, []);
  return humanizedRules.length ? humanizedRules : [{ summary: NO_RULE_MESSAGE }];
};

export const humanizeInvalidBranchesError = (branches) => {
  const sentence = [];
  if (branches.length > 1) {
    const lastBranch = branches.pop();
    sentence.push(branches.join(', '), s__('SecurityOrchestration| and '), lastBranch);
  } else {
    sentence.push(branches.join());
  }
  return sprintf(INVALID_PROTECTED_BRANCHES, { branches: sentence.join('') });
};
