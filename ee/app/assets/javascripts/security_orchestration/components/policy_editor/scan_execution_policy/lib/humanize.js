import cronstrue from 'cronstrue/i18n';
import { getPreferredLocales, sprintf, s__ } from '~/locale';
import { NO_RULE_MESSAGE } from '../../constants';
import { convertScannersToTitleCase } from '../../utils';

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Array} originalNamespaces strings representing namespaces
 * @returns {String}
 */
const humanizeNamespaces = (originalNamespaces) => {
  const namespaces = originalNamespaces ? [...originalNamespaces] : [];

  if (namespaces.length === 0) {
    return s__('SecurityOrchestration|all namespaces');
  }

  if (namespaces.length === 1) {
    return sprintf(s__('SecurityOrchestration|the %{namespaces} namespace'), {
      namespaces,
    });
  }

  const lastNamespace = namespaces.pop();
  return sprintf(s__('SecurityOrchestration|the %{namespaces} and %{lastNamespace} namespaces'), {
    namespaces: namespaces.join(', '),
    lastNamespace,
  });
};

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Object} agents object representing the agents and their namespaces
 * @returns {String}
 */
const humanizeAgent = (agents) => {
  const agentsEntries = Object.entries(agents);

  return sprintf(s__('SecurityOrchestration|%{agent} for %{namespaces}'), {
    agent: agentsEntries[0][0],
    namespaces: humanizeNamespaces(agentsEntries[0][1]?.namespaces),
  });
};

/**
 * Create a human-readable list of strings, adding the necessary punctuation and conjunctions
 * @param {Array} originalBranches strings representing branches
 * @returns {String}
 */
const humanizeBranches = (originalBranches) => {
  const branches = [...originalBranches];

  if (branches.length === 1) {
    return sprintf(s__('SecurityOrchestration|%{branches} branch'), {
      branches: branches[0],
    });
  }

  const lastBranch = branches.pop();
  return sprintf(s__('SecurityOrchestration|%{branches} and %{lastBranch} branches'), {
    branches: branches.join(', '),
    lastBranch,
  });
};

const humanizeCadence = (cadence) => {
  return cronstrue
    .toString(cadence, { locale: getPreferredLocales()[0], verbose: true })
    .toLowerCase();
};

const humanizePipelineRule = (rule) => {
  return sprintf(
    s__('SecurityOrchestration|Scan to be performed on every pipeline on the %{branches}'),
    { branches: humanizeBranches(rule.branches) },
  );
};

const humanizeScheduleRule = (rule) => {
  if (rule.agents) {
    return sprintf(
      s__('SecurityOrchestration|Scan to be performed by the agent named %{agents} %{cadence}'),
      {
        agents: humanizeAgent(rule.agents),
        cadence: humanizeCadence(rule.cadence),
      },
    );
  }

  return sprintf(s__('SecurityOrchestration|Scan to be performed %{cadence} on the %{branches}'), {
    cadence: humanizeCadence(rule.cadence),
    branches: humanizeBranches(rule.branches),
  });
};

const HUMANIZE_RULES_METHODS = {
  pipeline: humanizePipelineRule,
  schedule: humanizeScheduleRule,
};

/**
 * Create a human-readable version of the actions
 * @param {Array} actions [{"scan":"dast","scanner_profile":"Scanner Profile","site_profile":"Site Profile"},{"type":"secret_detection"}]
 * @returns {Array}
 */
export const humanizeActions = (actions) => {
  const scanners = actions.map((a) => a.scan);
  return [...new Set(convertScannersToTitleCase(scanners))];
};

/**
 * Create a human-readable version of the rules
 * @param {Array} rules [{"type":"schedule","cadence":"*\/10 * * * *","branches":["master"]},{"type":"pipeline","branches":["master"]}]
 * @returns {Array}
 */
export const humanizeRules = (rules) => {
  const humanizedRules = rules.reduce((acc, curr) => {
    return curr.branches || curr.agents ? [...acc, HUMANIZE_RULES_METHODS[curr.type](curr)] : acc;
  }, []);

  return humanizedRules.length ? humanizedRules : [NO_RULE_MESSAGE];
};
