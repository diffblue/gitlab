import cronstrue from 'cronstrue/i18n';
import { getPreferredLocales, sprintf, n__, s__ } from '~/locale';
import { NO_RULE_MESSAGE, ACTIONS } from '../../constants';
import { createHumanizedScanners } from '../../utils';

/**
 * Create a human-readable list of runner tags, adding the necessary punctuation and conjunctions
 * @param {string} scanner humanized scanner
 * @param {Array} originalTags all tags associated with the scanner
 * @returns {String} human-readable list of tags
 */
const humanizeCriteria = (scanner, originalActions) => {
  const tags = originalActions?.tags ? [...originalActions.tags] : [];
  const variables = originalActions?.variables ? { ...originalActions.variables } : {};

  const tagsMessage =
    tags.length > 0
      ? n__(
          'SecurityOrchestration|On runners with tag:',
          'SecurityOrchestration|On runners with the tags:',
          tags.length,
        )
      : s__('SecurityOrchestration|Automatically selected runners');

  const criteriaList = [
    {
      message: tagsMessage,
      tags,
      action: ACTIONS.tags,
    },
  ];
  if (Object.keys(variables).length) {
    criteriaList.push({
      message: s__('SecurityOrchestration|With the following customized CI variables:'),
      variables: Object.entries(variables).map(([variable, value]) => ({ variable, value })),
      action: ACTIONS.variables,
    });
  }

  return {
    message: sprintf(
      s__(
        'SecurityOrchestration|Run %{scannerStart}%{scanner}%{scannerEnd} with the following options:',
      ),
      { scanner },
    ),
    criteriaList,
  };
};

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
  return sprintf(s__('SecurityOrchestration|on every pipeline on the %{branches}'), {
    branches: humanizeBranches(rule.branches),
  });
};

const humanizeScheduleRule = (rule) => {
  if (rule.agents) {
    return sprintf(s__('SecurityOrchestration|by the agent named %{agents} %{cadence}'), {
      agents: humanizeAgent(rule.agents),
      cadence: humanizeCadence(rule.cadence),
    });
  }

  return sprintf(s__('SecurityOrchestration|%{cadence} on the %{branches}'), {
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
  // de-duplicate scanners and merge tags (if any)
  const scanners = actions.reduce((acc, action) => {
    if (!acc[action.scan]) {
      acc[action.scan] = { tags: [], variables: [] };
    }
    if (action.tags) {
      acc[action.scan].tags = [...acc[action.scan].tags, ...action.tags];
    }
    if (action.variables) {
      acc[action.scan].variables = { ...acc[action.scan].variables, ...action.variables };
    }
    return acc;
  }, {});

  const humanizedActions = Object.entries(scanners).map(([scanner, scannerActions]) => {
    const humanizedScanner = createHumanizedScanners([scanner])[0];
    return humanizeCriteria(humanizedScanner, scannerActions);
  });

  return humanizedActions;
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
