import { getPanelOptions } from 'ee/analytics/analytics_dashboards/utils/visualization_panel_options';
import { __ } from '~/locale';

describe('getPanelOptions', () => {
  it.each`
    visualizationType | hasTimeDimension | expectedResult
    ${'DataTable'}    | ${false}         | ${{}}
    ${'SingleStat'}   | ${false}         | ${{}}
    ${'LineChart'}    | ${false}         | ${{ xAxis: { name: __('Time'), type: 'time' }, yAxis: { name: __('Counts') } }}
    ${'ColumnChart'}  | ${false}         | ${{ xAxis: { name: __('Dimension'), type: 'category' }, yAxis: { name: __('Counts') } }}
    ${'ColumnChart'}  | ${true}          | ${{ xAxis: { name: __('Time'), type: 'time' }, yAxis: { name: __('Counts') } }}
  `(
    `with the visualization type $visualizationType and the time dimension is $hasTimeDimension it should return the correct options`,
    ({ visualizationType, hasTimeDimension, expectedResult }) => {
      const result = getPanelOptions(visualizationType, hasTimeDimension);

      expect(result).toStrictEqual(expectedResult);
    },
  );
});
