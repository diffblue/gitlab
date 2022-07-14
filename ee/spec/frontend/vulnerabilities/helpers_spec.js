import {
  getFormattedIssue,
  getAddRelatedIssueRequestParams,
  normalizeGraphQLVulnerability,
  formatIdentifierExternalIds,
} from 'ee/vulnerabilities/helpers';

describe('Vulnerabilities helpers', () => {
  describe('getFormattedIssue', () => {
    it.each([
      { iid: 135, web_url: 'some/url' },
      { iid: undefined, web_url: undefined },
    ])('returns formatted issue with expected properties for issue %s', (issue) => {
      const formattedIssue = getFormattedIssue(issue);

      expect(formattedIssue).toMatchObject({
        ...issue,
        reference: `#${issue.iid}`,
        path: issue.web_url,
      });
    });
  });

  describe('getAddRelatedIssueRequestParams', () => {
    const defaultPath = 'default/path';

    it.each`
      reference                                          | target_issue_iid                              | target_project_id
      ${'135'}                                           | ${'135'}                                      | ${defaultPath}
      ${'#246'}                                          | ${'246'}                                      | ${defaultPath}
      ${'https://localhost:3000/root/test/-/issues/357'} | ${'357'}                                      | ${'root/test'}
      ${'/root/test/-/issues/357'}                       | ${'/root/test/-/issues/357'}                  | ${defaultPath}
      ${'invalidReference'}                              | ${'invalidReference'}                         | ${defaultPath}
      ${'/?something/@#$%/@#$%/-/issues/1234'}           | ${'/?something/@#$%/@#$%/-/issues/1234'}      | ${defaultPath}
      ${'http://something/@#$%/@#$%/-/issues/1234'}      | ${'http://something/@#$%/@#$%/-/issues/1234'} | ${defaultPath}
    `(
      'gets correct request params for the reference "$reference"',
      async ({ reference, target_issue_iid, target_project_id }) => {
        const params = getAddRelatedIssueRequestParams(reference, defaultPath);

        expect(params).toMatchObject({ target_issue_iid, target_project_id });
      },
    );
  });

  describe('normalizeGraphQLVulnerability', () => {
    it('returns null when vulnerability is null', () => {
      expect(normalizeGraphQLVulnerability(null)).toBe(null);
    });

    it('normalizes the GraphQL response when the vulnerability is not null', () => {
      expect(
        normalizeGraphQLVulnerability({
          confirmedBy: { id: 'gid://gitlab/User/16' },
          resolvedBy: { id: 'gid://gitlab/User/16' },
          dismissedBy: { id: 'gid://gitlab/User/16' },
          state: 'DISMISSED',
          id: 'gid://gitlab/Vulnerability/54',
        }),
      ).toEqual({
        confirmedById: 16,
        resolvedById: 16,
        dismissedById: 16,
        state: 'dismissed',
        id: 54,
      });
    });
  });

  describe('formatIdentifierExternalIds', () => {
    const identifiers = {
      externalType: 'external type',
      externalId: 'external id',
      name: 'name',
    };

    it('returns the correct format', () => {
      const { externalType, externalId, name } = identifiers;

      expect(formatIdentifierExternalIds(identifiers)).toEqual(
        `[${externalType}]-[${externalId}]-[${name}]`,
      );
    });
  });
});
