import { sortBy } from 'lodash';

const sortData = (data) => sortBy(data, (item) => item[1]).reverse();

export const formatChartData = (data, labels) =>
  sortData(data.map((val, index) => [labels[index], val]));
