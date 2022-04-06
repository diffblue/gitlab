import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId, convertNodeIdsFromGraphQLIds } from '~/graphql_shared/utils';
import { createComplianceViolation } from '../mock_data';

describe('mapViolations', () => {
  it('returns the expected result', () => {
    const violation = createComplianceViolation();
    const mappedViolation = mapViolations([violation])[0];

    expect(mappedViolation).toMatchObject({
      mergeRequest: {
        committers: convertNodeIdsFromGraphQLIds(violation.mergeRequest.committers.nodes),
        approvedByUsers: convertNodeIdsFromGraphQLIds(violation.mergeRequest.approvedBy.nodes),
        participants: convertNodeIdsFromGraphQLIds(violation.mergeRequest.participants.nodes),
        reference: violation.mergeRequest.ref,
        mergedBy: {
          ...convertObjectPropsToSnakeCase(violation.mergeRequest.mergeUser),
          id: getIdFromGraphQLId(violation.mergeRequest.mergeUser?.id),
        },
      },
      violatingUser: {
        ...violation.violatingUser,
        id: getIdFromGraphQLId(violation.violatingUser.id),
      },
    });
  });
});
