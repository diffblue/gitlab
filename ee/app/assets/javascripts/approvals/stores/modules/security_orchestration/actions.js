import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import projectScanResultPoliciesQuery from 'ee/security_orchestration/graphql/queries/project_scan_result_policies.query.graphql';
import deprecatedScanResultPoliciesQuery from 'ee/security_orchestration/graphql/queries/scan_result_policies.query.graphql';
import { gqClient } from 'ee/security_orchestration/utils';
import { fromYaml } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/from_yaml';
import * as types from './mutation_types';

export const fetchScanResultPolicies = ({ commit }, { fullPath, featureFlagEnabled }) => {
  gqClient
    .query({
      query: featureFlagEnabled
        ? projectScanResultPoliciesQuery
        : deprecatedScanResultPoliciesQuery,
      variables: { fullPath },
    })
    .then(({ data }) => {
      const policies = data.namespace?.scanResultPolicies?.nodes || [];
      const parsedPolicies = policies
        .map((rawPolicy) => {
          try {
            return {
              ...fromYaml(rawPolicy.yaml),
              isSelected: false,
              approvers: [...rawPolicy.userApprovers, ...rawPolicy.groupApprovers],
              source: rawPolicy.source || { project: { fullPath } },
            };
          } catch (e) {
            return null;
          }
        })
        .filter((policy) => policy);
      commit(types.SET_SCAN_RESULT_POLICIES, parsedPolicies);
    })
    .catch((error) => {
      commit(types.SCAN_RESULT_POLICIES_FAILED, error);
      createFlash({
        message: s__(
          'SecurityOrchestration|An error occurred while fetching the scan result policies.',
        ),
      });
      Sentry.captureException(error);
    });
};
