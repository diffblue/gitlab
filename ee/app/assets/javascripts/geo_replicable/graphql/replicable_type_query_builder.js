import { gql } from '@apollo/client/core';
import PageInfo from '~/graphql_shared/fragments/page_info.fragment.graphql';

export default (graphQlFieldName) => {
  return gql`
    query($first: Int, $last: Int, $before: String!, $after: String!) {
      geoNode {
        ${graphQlFieldName}(first: $first, last: $last, before: $before, after: $after) {
          pageInfo {
            ...PageInfo
          }
          nodes {
            id
            state
            retryCount
            lastSyncFailure
            retryAt
            lastSyncedAt
            verifiedAt
            createdAt
          }
        }
      }
    }
    ${PageInfo}
  `;
};
