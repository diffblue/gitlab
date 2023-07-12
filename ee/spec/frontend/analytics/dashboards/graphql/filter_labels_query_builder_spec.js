import { print } from 'graphql/language/printer';
import filterLabelsQueryBuilder from 'ee/analytics/dashboards/graphql/filter_labels_query_builder';
import { filterLabelsGroupQuery, filterLabelsProjectQuery } from '../mock_data';

describe('filterLabelsQueryBuilder', () => {
  it('returns the query for a group', () => {
    const query = filterLabelsQueryBuilder(['zero', 'one'], false);
    expect(print(query)).toEqual(filterLabelsGroupQuery);
  });

  it('returns the query for a project', () => {
    const query = filterLabelsQueryBuilder(['zero', 'one'], true);
    expect(print(query)).toEqual(filterLabelsProjectQuery);
  });
});
