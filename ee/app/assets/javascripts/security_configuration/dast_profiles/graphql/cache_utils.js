import { gql } from '@apollo/client/core';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';

/**
 * Evicts a profile from the cache
 *
 * @param profile
 * @param store
 */
export const removeProfile = ({ profile, store }) => store.evict({ id: store.identify(profile) });

/**
 * Returns an object representing a optimistic response for site-profile deletion
 *
 * @param mutationName
 * @param payloadTypeName
 * @returns {{[p: string]: string, __typename: string}}
 */
export const dastProfilesDeleteResponse = ({ mutationName, payloadTypeName }) => ({
  // eslint-disable-next-line @gitlab/require-i18n-strings
  __typename: 'Mutation',
  [mutationName]: {
    __typename: payloadTypeName,
    errors: [],
  },
});

export const updateSiteProfilesStatuses = ({ fullPath, normalizedTargetUrl, status, store }) => {
  const queryBody = {
    query: dastSiteProfilesQuery,
    variables: {
      fullPath,
    },
  };

  const sourceData = store.readQuery(queryBody);

  const profilesWithNormalizedTargetUrl = sourceData.project.siteProfiles.nodes.map((node) =>
    node.normalizedTargetUrl === normalizedTargetUrl ? node : [],
  );

  profilesWithNormalizedTargetUrl.forEach(({ id }) => {
    store.writeFragment({
      id: `DastSiteProfile:${id}`,
      fragment: gql`
        fragment profile on DastSiteProfile {
          validationStatus
          __typename
        }
      `,
      data: {
        validationStatus: status,
        __typename: 'DastSiteProfile',
      },
    });
  });
};
