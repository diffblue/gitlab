import { parsePikadayDate, pikadayToString } from '~/lib/utils/datetime_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  AVAILABLE_TOKEN_TYPES,
  AUDIT_FILTER_CONFIGS,
  ENTITY_TYPES,
  createBlankHeader,
} from './constants';
import { parseUsername, displayUsername } from './token_utils';

export const getTypeFromEntityType = (entityType) => {
  return AUDIT_FILTER_CONFIGS.find(
    ({ entityType: configEntityType }) => configEntityType === entityType,
  )?.type;
};

export const getEntityTypeFromType = (type) => {
  return AUDIT_FILTER_CONFIGS.find(({ type: configType }) => configType === type)?.entityType;
};

export const parseAuditEventSearchQuery = ({
  created_after: createdAfter,
  created_before: createdBefore,
  entity_type: entityType,
  entity_username: entityUsername,
  author_username: authorUsername,
  ...restOfParams
}) => ({
  ...restOfParams,
  created_after: createdAfter ? parsePikadayDate(createdAfter) : null,
  created_before: createdBefore ? parsePikadayDate(createdBefore) : null,
  entity_type: getTypeFromEntityType(entityType),
  entity_username: displayUsername(entityUsername),
  author_username: displayUsername(authorUsername),
});

export const createAuditEventSearchQuery = ({ filterValue, startDate, endDate, sortBy }) => {
  const entityValue = filterValue.find((value) => AVAILABLE_TOKEN_TYPES.includes(value.type));
  const entityType = getEntityTypeFromType(entityValue?.type);
  const filterData = entityValue?.value.data;

  const params = {
    created_after: startDate ? pikadayToString(startDate) : null,
    created_before: endDate ? pikadayToString(endDate) : null,
    sort: sortBy,
    entity_type: entityType,
    entity_id: null,
    entity_username: null,
    author_username: null,
    // When changing the search parameters, we should be resetting to the first page
    page: null,
  };

  switch (entityType) {
    case ENTITY_TYPES.USER:
      params.entity_username = parseUsername(filterData);
      break;
    case ENTITY_TYPES.AUTHOR:
      params.author_username = parseUsername(filterData);
      break;
    default:
      params.entity_id = filterData;
  }

  return params;
};

export const mapItemHeadersToFormData = (item, settings = {}) => {
  const headers = item?.headers?.nodes || [];

  return (
    headers
      .map(({ id, key, value }) => ({
        ...createBlankHeader(),
        id,
        name: key,
        value,
        ...settings,
      }))
      // Sort the headers so they appear in the order they were created
      // The GraphQL endpoint returns them in the reverse order of this
      .sort((a, b) => getIdFromGraphQLId(a.id) - getIdFromGraphQLId(b.id))
  );
};

export const mapAllMutationErrors = (mutations, name) => {
  return Promise.allSettled(mutations).then((results) => {
    const rejected = results.filter((r) => r.status === 'rejected').map((r) => r.reason);

    if (rejected.length > 0) {
      throw rejected[0];
    }

    return results
      .filter((r) => r.status === 'fulfilled')
      .map((r) => r.value.data[name].errors)
      .reduce((r, errors) => r.concat(errors), [])
      .filter(Boolean);
  });
};
