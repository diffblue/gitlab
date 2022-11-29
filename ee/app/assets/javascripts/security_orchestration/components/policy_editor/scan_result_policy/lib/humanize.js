import { sprintf, s__ } from '~/locale';
import { NO_RULE_MESSAGE, INVALID_PROTECTED_BRANCHES } from '../../constants';
import { convertScannersToTitleCase } from '../../utils';

/**
 * Simple logic for indefinite articles which does not include the exceptions
 * @param {String} word string representing the word to be considered
 * @returns {String}
 */
const articleForWord = (word) => {
  const vowels = ['a', 'e', 'i', 'o', 'u'];

  return vowels.includes(word[0].toLowerCase())
    ? s__('SecurityOrchestration|an')
    : s__('SecurityOrchestration|a');
};

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Array} items strings representing items to compose the final sentence
 * @param {String} singular string to be used for single items
 * @param {String} plural string to be used for multiple items
 * @returns {String}
 */
const humanizeItems = ({
  items,
  singular,
  plural,
  hasArticle = false,
  hasTextBeforeItems = false,
}) => {
  if (!items) {
    return '';
  }

  let noun = '';

  if (singular && plural) {
    noun = items.length > 1 ? plural : singular;
  }

  const finalSentence = [];

  if (hasArticle && items.length === 1) {
    finalSentence.push(`${articleForWord(items[0])} `);
  }

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
const humanizeBranches = (branches) => {
  const hasNoBranch = branches.length === 0;

  if (hasNoBranch) {
    return s__('SecurityOrchestration|all protected branches');
  }

  return sprintf(s__('SecurityOrchestration|the %{branches}'), {
    branches: humanizeItems({
      items: branches,
      singular: s__('SecurityOrchestration|branch'),
      plural: s__('SecurityOrchestration|branches'),
    }),
  });
};

/**
 * Create a human-readable version of the scanners
 * @param {Array} scanners
 * @returns {String}
 */
const humanizeScanners = (scanners) => {
  const hasEmptyScanners = scanners.length === 0;

  if (hasEmptyScanners) {
    return s__('SecurityOrchestration|Any scanner finds');
  }

  return sprintf(s__('SecurityOrchestration|%{scanners}'), {
    scanners: humanizeItems({
      items: scanners,
      singular: s__('SecurityOrchestration|scanner finds'),
      plural: s__('SecurityOrchestration|scanners find'),
    }),
  });
};

/**
 * Create a human-readable version of the rule
 * @param {Object} rule {type: 'scan_finding', branches: ['master'], scanners: ['container_scanning'], vulnerabilities_allowed: 1, severity_levels: ['critical']}
 * @returns {String}
 */
const humanizeRule = (rule) => {
  return sprintf(
    s__(
      'SecurityOrchestration|%{scanners} %{severities} in an open merge request targeting %{branches}.',
    ),
    {
      scanners: humanizeScanners(convertScannersToTitleCase(rule.scanners)),
      severities: humanizeItems({
        items: rule.severity_levels,
        singular: s__('SecurityOrchestration|vulnerability'),
        plural: s__('SecurityOrchestration|vulnerabilities'),
        hasArticle: true,
      }),
      branches: humanizeBranches(rule.branches),
    },
  );
};

/**
 * Create a human-readable version of the rules
 * @param {Array} rules [{type: 'scan_finding', branches: ['master'], scanners: ['container_scanning'], vulnerabilities_allowed: 1, severity_levels: ['critical']}]
 * @returns {Array}
 */
export const humanizeRules = (rules) => {
  const humanizedRules = rules.reduce((acc, curr) => {
    return [...acc, humanizeRule(curr)];
  }, []);
  return humanizedRules.length ? humanizedRules : [NO_RULE_MESSAGE];
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
