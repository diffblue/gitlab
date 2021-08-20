import { convertToTitleCase, humanize } from '~/lib/utils/text_utility';
import { sprintf, s__, n__ } from '~/locale';

const getActionText = (scanType) =>
  sprintf(s__('SecurityOrchestration|Executes a %{scanType} scan'), {
    scanType: convertToTitleCase(humanize(scanType)),
  });

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Array} branches strings representing branches
 * @returns {String}
 */
const humanizeBranches = (originalBranches) => {
  const branches = [...originalBranches];

  const plural = n__('branch', 'branches', branches.length);

  if (branches.length <= 1) {
    return sprintf(s__('SecurityOrchestration|%{branches} %{plural}'), {
      branches: branches.join(','),
      plural,
    });
  }

  const lastBranch = branches.pop();
  return sprintf(s__('SecurityOrchestration|%{branches} and %{lastBranch} %{plural}'), {
    branches: branches.join(', '),
    lastBranch,
    plural,
  });
};

const humanizeCadence = (cadence) => {
  return cadence;
};

const humanizePipelineRule = (rule) => {
  return sprintf(
    s__('SecurityOrchestration|Scan to be performed on every pipeline on the %{branches}'),
    { branches: humanizeBranches(rule.branches) },
  );
};

const humanizeScheduleRule = (rule) => {
  return sprintf(
    s__('SecurityOrchestration|Scan to be performed every %{cadence} on the %{branches}'),
    { cadence: humanizeCadence(rule.cadence), branches: humanizeBranches(rule.branches) },
  );
};

const HUMANIZE_RULES_METHODS = {
  pipeline: humanizePipelineRule,
  schedule: humanizeScheduleRule,
};

/**
 * Create a human-readable version of the actions
 * @param {Array} actions [{"scan":"dast","scanner_profile":"Scanner Profile","site_profile":"Site Profile"},{"type":"secret_detection"}]
 * @returns {Set}
 */
export const humanizeActions = (actions) => {
  return new Set(actions.map((action) => getActionText(action.scan)));
};

/**
 * Create a human-readable version of the rules
 * @param {Array} rules [{"type":"schedule","cadence":"*\/10 * * * *","branches":["master"]},{"type":"pipeline","branches":["master"]}]
 * @returns {Array}
 */
export const humanizeRules = (rules) => {
  return rules.map((r) => HUMANIZE_RULES_METHODS[r.type](r) || '');
};
