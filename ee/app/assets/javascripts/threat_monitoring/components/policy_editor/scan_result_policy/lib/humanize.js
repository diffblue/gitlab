import { sprintf, s__, n__ } from '~/locale';
import { NO_RULE_MESSAGE } from '../../constants';

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
    finalSentence.push(items.join(', '));
    finalSentence.push(s__('SecurityOrchestration| or '));
    finalSentence.push(lastItem);
  }

  if (!hasTextBeforeItems && noun) {
    finalSentence.push(` ${noun}`);
  }

  return finalSentence.join('');
};

/**
 * Create a human-readable string, adding the necessary punctuation and conjunctions
 * @param {Object} action containing or not arrays of string and integers representing approvers
 * @returns {String}
 */
const humanizeApprovers = (action) => {
  const userApprovers = humanizeItems({ items: action.user_approvers, singular: '', plural: '' });
  const userApproversIds = humanizeItems({
    items: action.user_approvers_ids,
    singular: s__('SecurityOrchestration|user with id'),
    plural: s__('SecurityOrchestration|users with ids'),
    hasArticle: false,
    hasTextBeforeItems: true,
  });
  const groupApprovers = humanizeItems({
    items: action.group_approvers,
    singular: s__('SecurityOrchestration|members of the group'),
    plural: s__('SecurityOrchestration|members of groups'),
    hasArticle: false,
    hasTextBeforeItems: true,
  });
  const groupApproversIds = humanizeItems({
    items: action.group_approvers_ids,
    singular: s__('SecurityOrchestration|members of the group with id'),
    plural: s__('SecurityOrchestration|members of groups with ids'),
    hasArticle: false,
    hasTextBeforeItems: true,
  });

  const conjunctionOr = s__('SecurityOrchestration| or ');

  let finalSentence = userApprovers;

  if (finalSentence && userApproversIds) {
    finalSentence += conjunctionOr;
  }

  finalSentence += userApproversIds;

  if (finalSentence && groupApprovers) {
    finalSentence += conjunctionOr;
  }

  finalSentence += groupApprovers;

  if (finalSentence && groupApproversIds) {
    finalSentence += conjunctionOr;
  }

  finalSentence += groupApproversIds;

  return finalSentence;
};

/**
 * Create a human-readable version of the action
 * @param {Object} action {type: 'require_approval', approvals_required: 1, approvers: Array(1)}
 * @returns {String}
 */
export const humanizeAction = (action) => {
  const plural = n__('approval', 'approvals', action.approvals_required);

  return sprintf(
    s__(
      'SecurityOrchestration|Require %{approvals} %{plural} from %{approvers} if any of the following occur:',
    ),
    {
      approvals: action.approvals_required,
      plural,
      approvers: humanizeApprovers(action),
    },
  );
};

/**
 * Create a human-readable version of the rule
 * @param {Object} rule {type: 'scan_finding', branches: ['master'], scanners: ['container_scanning'], vulnerabilities_allowed: 1, severity_levels: ['critical']}
 * @returns {String}
 */
const humanizeRule = (rule) => {
  return sprintf(
    s__(
      'SecurityOrchestration|The %{scanners} %{severities} in an open merge request targeting the %{branches}.',
    ),
    {
      scanners: humanizeItems({
        items: rule.scanners,
        singular: s__('SecurityOrchestration|scanner finds'),
        plural: s__('SecurityOrchestration|scanners find'),
      }),
      severities: humanizeItems({
        items: rule.severity_levels,
        singular: s__('SecurityOrchestration|vulnerability'),
        plural: s__('SecurityOrchestration|vulnerabilities'),
        hasArticle: true,
      }),
      branches: humanizeItems({
        items: rule.branches,
        singular: s__('SecurityOrchestration|branch'),
        plural: s__('SecurityOrchestration|branches'),
      }),
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
