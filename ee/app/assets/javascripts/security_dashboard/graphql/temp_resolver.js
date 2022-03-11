// Note: this is behind a feature flag and only a placeholder
// until the actual GraphQL fields have been added
// https://gitlab.com/gitlab-org/gitlab/-/issues/349910
export default {
  Query: {
    vulnerability() {
      /* eslint-disable @gitlab/require-i18n-strings */
      return {
        __typename: 'Vulnerability',
        id: 'id: "gid://gitlab/Vulnerability/295"',
        identifiers: [{ externalType: 'cwe', __typename: 'VulnerabilityIdentifier' }],
        securityTrainingUrls: [
          {
            __typename: 'SecurityTrainingUrls',
            id: 101,
            name: 'Kontra',
            url: null,
            status: 'COMPLETED',
          },
          {
            __typename: 'SecurityTrainingUrls',
            id: 102,
            name: 'Secure Code Warrior',
            url: 'https://www.securecodewarrior.com/',
            status: 'COMPLETED',
          },
        ],
      };
    },
  },
};
