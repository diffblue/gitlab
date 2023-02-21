import { mapProjects, mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { convertNodeIdsFromGraphQLIds, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { createComplianceFrameworksResponse, createComplianceViolation } from '../mock_data';

describe('Compliance report graphql mappers', () => {
  describe('mapViolations', () => {
    it('returns the expected result', () => {
      const violation = createComplianceViolation();
      const mappedViolation = mapViolations([violation])[0];

      expect(mappedViolation).toMatchObject({
        mergeRequest: {
          committers: convertNodeIdsFromGraphQLIds(violation.mergeRequest.committers.nodes),
          approvedByUsers: convertNodeIdsFromGraphQLIds(violation.mergeRequest.approvedBy.nodes),
          participants: convertNodeIdsFromGraphQLIds(violation.mergeRequest.participants.nodes),
          mergeUser: {
            ...violation.mergeRequest.mergeUser,
            id: getIdFromGraphQLId(violation.mergeRequest.mergeUser?.id),
          },
          project: {
            ...violation.project,
            id: getIdFromGraphQLId(violation.mergeRequest.project?.id),
            complianceFramework: violation.mergeRequest.project?.complianceFrameworks?.nodes[0],
          },
        },
        violatingUser: {
          ...violation.violatingUser,
          id: getIdFromGraphQLId(violation.violatingUser.id),
        },
      });
    });
  });

  describe('mapProjects', () => {
    it('returns the expected result', () => {
      const response = createComplianceFrameworksResponse();
      const mappedProject = mapProjects(response.data.group.projects.nodes)[0];

      expect(mappedProject).toMatchObject({
        id: 'gid://gitlab/Project/0',
        name: 'Gitlab Shell',
        fullPath: 'gitlab-org/gitlab-shell',
        complianceFrameworks: [
          {
            id: 'gid://gitlab/ComplianceManagement::Framework/1',
            name: 'some framework',
            description: 'this is a framework',
            default: false,
            color: '#3cb371',
            __typename: 'ComplianceFramework',
          },
        ],
        __typename: 'Project',
      });
    });
  });
});
