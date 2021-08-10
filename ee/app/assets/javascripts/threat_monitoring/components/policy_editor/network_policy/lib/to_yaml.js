import { safeDump } from 'js-yaml';
import { POLICY_TYPE_COMPONENT_OPTIONS } from 'ee/threat_monitoring/components/constants';
import { EndpointMatchModeAny, DisabledByLabel } from './constants';
import { ruleSpec } from './rules';
import { labelSelector } from './utils';

/*
 Return kubernetes resource specification object for a policy.
*/
function spec({ rules, isEnabled, endpointMatchMode, endpointLabels }) {
  const matchLabels =
    endpointMatchMode === EndpointMatchModeAny ? {} : labelSelector(endpointLabels);
  const policySpec = {};

  policySpec.endpointSelector = Object.keys(matchLabels).length > 0 ? { matchLabels } : {};
  rules.forEach((rule) => {
    const { direction } = rule;
    if (!policySpec[direction]) policySpec[direction] = [];

    policySpec[direction].push(ruleSpec(rule));
  });

  if (!isEnabled) {
    policySpec.endpointSelector.matchLabels = {
      ...policySpec.endpointSelector.matchLabels,
      [DisabledByLabel]: 'gitlab',
    };
  }

  return policySpec;
}

/*
 Return yaml representation of a policy.
*/
export default function toYaml(policy) {
  const { annotations, name, resourceVersion, description, labels } = policy;
  const metadata = { name };
  if (annotations) {
    metadata.annotations = annotations;
  }
  if (labels) {
    metadata.labels = labels;
  }
  if (resourceVersion) {
    metadata.resourceVersion = resourceVersion;
  }

  const policySpec = {
    apiVersion: 'cilium.io/v2',
    kind: POLICY_TYPE_COMPONENT_OPTIONS.container.yamlIndicator,
  };

  if (description?.length > 0) {
    policySpec.description = description;
  }

  // We want description at a specific position to have yaml in a common form.
  Object.assign(policySpec, {
    metadata,
    spec: spec(policy),
  });

  return safeDump(policySpec, { noArrayIndent: true });
}
