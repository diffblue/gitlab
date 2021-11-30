export const vulnerabilityExternalIssueLinkCreateMockFactory = ({ errors = [] } = {}) => ({
  data: {
    vulnerabilityExternalIssueLinkCreate: {
      errors,
      externalIssueLink: {
        id: '1',
        externalIssue: {
          webUrl: 'http://foo.bar',
        },
      },
    },
  },
});
