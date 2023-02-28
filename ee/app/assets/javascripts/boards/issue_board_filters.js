import issueBoardFiltersCE from '~/boards/issue_board_filters';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ITERATIONS_CADENCE } from '~/graphql_shared/constants';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import searchIterationQuery from '../issues/list/queries/search_iterations.query.graphql';
import searchIterationCadencesQuery from '../issues/list/queries/search_iteration_cadences.query.graphql';

export default function issueBoardFilters(apollo, fullPath, isGroupBoard) {
  const boardType = isGroupBoard ? WORKSPACE_GROUP : WORKSPACE_PROJECT;

  const fetchIterations = (searchTerm) => {
    const id = Number(searchTerm);
    let variables = { fullPath, search: searchTerm, isProject: !isGroupBoard };

    if (!Number.isNaN(id) && searchTerm !== '') {
      variables = { fullPath, id, isProject: !isGroupBoard };
    }

    return apollo
      .query({
        query: searchIterationQuery,
        variables,
      })
      .then(({ data }) => {
        return data[boardType]?.iterations.nodes;
      });
  };

  const fetchIterationCadences = (searchTerm) => {
    const id = Number(searchTerm);
    let variables = { fullPath, title: searchTerm, isProject: !isGroupBoard };

    if (!Number.isNaN(id) && searchTerm !== '') {
      variables = {
        fullPath,
        id: convertToGraphQLId(TYPENAME_ITERATIONS_CADENCE, id),
        isProject: !isGroupBoard,
      };
    }

    return apollo
      .query({
        query: searchIterationCadencesQuery,
        variables,
      })
      .then(({ data }) => {
        return data[boardType]?.iterationCadences?.nodes;
      });
  };

  const { fetchUsers, fetchLabels, fetchMilestones } = issueBoardFiltersCE(
    apollo,
    fullPath,
    isGroupBoard,
  );

  return {
    fetchLabels,
    fetchUsers,
    fetchMilestones,
    fetchIterations,
    fetchIterationCadences,
  };
}
