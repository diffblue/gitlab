import {
  GlEmptyState,
  GlLoadingIcon,
  GlDropdown,
  GlDropdownItem,
  GlButton,
  GlAlert,
} from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import ProductivityApp from 'ee/analytics/productivity_analytics/components/app.vue';
import MetricChart from 'ee/analytics/productivity_analytics/components/metric_chart.vue';
import MergeRequestTable from 'ee/analytics/productivity_analytics/components/mr_table.vue';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import { getStoreConfig } from 'ee/analytics/productivity_analytics/store';
import Scatterplot from 'ee/analytics/shared/components/scatterplot.vue';
import { TEST_HOST } from 'helpers/test_constants';
import {
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { mockFilters } from '../mock_data';

Vue.use(Vuex);

describe('ProductivityApp component', () => {
  let wrapper;
  let mock;
  let mockStore;

  const propsData = {
    emptyStateSvgPath: TEST_HOST,
    noAccessSvgPath: TEST_HOST,
  };

  const chartsActionSpies = {
    resetMainChartSelection: jest.fn(),
  };

  const tableActionSpies = {
    setSortField: jest.fn(),
    setPage: jest.fn(),
    toggleSortOrder: jest.fn(),
    setColumnMetric: jest.fn(),
  };

  const mainChartData = { 1: 2, 2: 3 };

  const createComponent = ({ props = {}, options = {} } = {}) => {
    const {
      modules: { charts, table, ...modules },
      ...storeConfig
    } = getStoreConfig();
    mockStore = new Vuex.Store({
      ...storeConfig,
      modules: {
        charts: {
          ...charts,
          actions: {
            ...charts.actions,
            ...chartsActionSpies,
          },
        },
        table: {
          ...table,
          actions: {
            ...table.actions,
            ...tableActionSpies,
          },
        },
        ...modules,
      },
    });
    wrapper = shallowMount(ProductivityApp, {
      store: mockStore,
      propsData: {
        ...propsData,
        ...props,
      },
      ...options,
    });

    mockStore.dispatch('setEndpoint', TEST_HOST);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    mock.restore();
  });

  const findMainMetricChart = () => wrapper.findComponent({ ref: 'mainChart' });
  const findClearFilterButton = () => wrapper.findComponent({ ref: 'clearChartFiltersBtn' });
  const findSecondaryChartsSection = () => wrapper.findComponent({ ref: 'secondaryCharts' });
  const findTimeBasedMetricChart = () => wrapper.findComponent({ ref: 'timeBasedChart' });
  const findCommitBasedMetricChart = () => wrapper.findComponent({ ref: 'commitBasedChart' });
  const findScatterplotMetricChart = () => wrapper.findComponent({ ref: 'scatterplot' });
  const findMrTableSortSection = () => wrapper.find('.js-mr-table-sort');
  const findSortFieldDropdown = () => findMrTableSortSection().findComponent(GlDropdown);
  const findSortOrderToggle = () => findMrTableSortSection().findComponent(GlButton);
  const findMrTableSection = () => wrapper.find('.js-mr-table');
  const findMrTable = () => findMrTableSection().findComponent(MergeRequestTable);

  describe('template', () => {
    describe('without a group being selected', () => {
      it('renders the empty state illustration', () => {
        createComponent();
        const emptyState = wrapper.findComponent(GlEmptyState);
        expect(emptyState.exists()).toBe(true);

        expect(emptyState.props('svgPath')).toBe(propsData.emptyStateSvgPath);
      });
    });

    describe('with a group being selected', () => {
      beforeEach(() => {
        mockStore.dispatch('filters/setInitialData', {
          skipFetch: true,
          data: {
            mergedAfter: new Date('2019-09-01'),
            mergedBefore: new Date('2019-09-02'),
          },
        });
        mockStore.dispatch('filters/setGroupNamespace', 'gitlab-org');
        mock.onGet(mockStore.state.endpoint).replyOnce(HTTP_STATUS_OK);
      });

      describe('user has no access to the group', () => {
        beforeEach(() => {
          createComponent();
          const error = { response: { status: HTTP_STATUS_FORBIDDEN } };
          mockStore.dispatch('charts/receiveChartDataError', {
            chartKey: chartKeys.main,
            error,
          });
          mockStore.state.charts.charts[chartKeys.main].errorCode = HTTP_STATUS_FORBIDDEN;
        });

        it('renders the no access illustration', () => {
          const emptyState = wrapper.findComponent(GlEmptyState);
          expect(emptyState.exists()).toBe(true);

          expect(emptyState.props('svgPath')).toBe(propsData.noAccessSvgPath);
        });
      });

      describe('user has access to the group', () => {
        beforeEach(async () => {
          mockStore.state.charts.charts[chartKeys.main].errorCode = null;

          await nextTick();
        });

        describe('when the main chart is loading', () => {
          beforeEach(() => {
            createComponent();
            mockStore.dispatch('charts/requestChartData', chartKeys.main);
          });

          it('renders a metric chart component for the main chart', () => {
            expect(findMainMetricChart().exists()).toBe(true);
          });

          it('sets isLoading=true on the metric chart', () => {
            expect(findMainMetricChart().props('isLoading')).toBe(true);
          });

          it('does not render any other charts', () => {
            expect(findSecondaryChartsSection().exists()).toBe(false);
          });

          it('does not render the MR table', () => {
            expect(findMrTableSortSection().exists()).toBe(false);
            expect(findMrTableSection().exists()).toBe(false);
          });
        });

        describe('when the main chart finished loading', () => {
          describe('and has data', () => {
            beforeEach(() => {
              createComponent();
              mockStore.dispatch('charts/receiveChartDataSuccess', {
                chartKey: chartKeys.main,
                data: mainChartData,
              });
            });

            it('sets isLoading=false on the metric chart', () => {
              expect(findMainMetricChart().props('isLoading')).toBe(false);
            });

            it('passes non-empty chartData to the metric chart', () => {
              expect(findMainMetricChart().props('chartData')).not.toEqual([]);
            });

            describe('when an item on the chart is clicked', () => {
              beforeEach(() => {
                jest.spyOn(mockStore, 'dispatch');

                const data = {
                  chart: null,
                  params: {
                    data: {
                      value: [0, 1],
                    },
                  },
                };

                findMainMetricChart()
                  .findComponent(GlColumnChart)
                  .vm.$emit('chartItemClicked', data);
              });

              it('dispatches updateSelectedItems action', () => {
                expect(mockStore.dispatch).toHaveBeenCalledWith('charts/updateSelectedItems', {
                  chartKey: chartKeys.main,
                  item: 0,
                });
              });
            });

            describe('when the main chart has selected items', () => {
              beforeEach(() => {
                mockStore.state.charts.charts[chartKeys.main].selected = [1];
              });

              it('renders the "Clear chart data" button', () => {
                expect(findClearFilterButton().exists()).toBe(true);
              });

              it('dispatches resetMainChartSelection action when the user clicks on the "Clear chart data" button', () => {
                findClearFilterButton().vm.$emit('click');

                expect(chartsActionSpies.resetMainChartSelection).toHaveBeenCalled();
              });
            });

            describe('Time based histogram', () => {
              it('renders a metric chart component', () => {
                expect(findTimeBasedMetricChart().exists()).toBe(true);
              });

              describe('when chart finished loading', () => {
                describe('and the chart has data', () => {
                  beforeEach(() => {
                    mockStore.dispatch('charts/receiveChartDataSuccess', {
                      chartKey: chartKeys.timeBasedHistogram,
                      data: { 1: 2, 2: 3 },
                    });
                  });

                  it('sets isLoading=false on the metric chart', () => {
                    expect(findTimeBasedMetricChart().props('isLoading')).toBe(false);
                  });

                  it('passes non-empty chartData to the metric chart', () => {
                    expect(findTimeBasedMetricChart().props('chartData')).not.toEqual([]);
                  });

                  describe('when the user changes the metric', () => {
                    beforeEach(() => {
                      jest.spyOn(mockStore, 'dispatch');
                      findTimeBasedMetricChart().vm.$emit('metricTypeChange', 'time_to_merge');
                    });

                    it('should call setMetricType  when `metricTypeChange` is emitted on the metric chart', () => {
                      expect(mockStore.dispatch).toHaveBeenCalledWith('charts/setMetricType', {
                        metricType: 'time_to_merge',
                        chartKey: chartKeys.timeBasedHistogram,
                      });
                    });
                  });
                });
              });
            });

            describe('Commit based histogram', () => {
              it('renders a metric chart component', () => {
                expect(findCommitBasedMetricChart().exists()).toBe(true);
              });

              describe('when chart finished loading', () => {
                describe('and the chart has data', () => {
                  beforeEach(() => {
                    mockStore.dispatch('charts/receiveChartDataSuccess', {
                      chartKey: chartKeys.commitBasedHistogram,
                      data: { 1: 2, 2: 3 },
                    });
                  });

                  it('sets isLoading=false on the metric chart', () => {
                    expect(findCommitBasedMetricChart().props('isLoading')).toBe(false);
                  });

                  it('passes non-empty chartData to the metric chart', () => {
                    expect(findCommitBasedMetricChart().props('chartData')).not.toEqual([]);
                  });

                  describe('when the user changes the metric', () => {
                    beforeEach(async () => {
                      jest.spyOn(mockStore, 'dispatch');
                      findCommitBasedMetricChart().vm.$emit('metricTypeChange', 'loc_per_commit');
                      await nextTick();
                    });

                    it('should call setMetricType  when `metricTypeChange` is emitted on the metric chart', () => {
                      expect(mockStore.dispatch).toHaveBeenCalledWith('charts/setMetricType', {
                        metricType: 'loc_per_commit',
                        chartKey: chartKeys.commitBasedHistogram,
                      });
                    });

                    it("should update the chart's x axis label", () => {
                      const columnChart = findCommitBasedMetricChart().findComponent(GlColumnChart);
                      expect(columnChart.props('xAxisTitle')).toBe('Number of LOCs per commit');
                    });
                  });
                });
              });
            });

            describe('Scatterplot', () => {
              it('renders a metric chart component', () => {
                expect(findScatterplotMetricChart().exists()).toBe(true);
              });

              describe('when chart finished loading', () => {
                describe('and the chart has data', () => {
                  beforeEach(() => {
                    mockStore.dispatch('charts/receiveChartDataSuccess', {
                      chartKey: chartKeys.scatterplot,
                      data: {
                        1: { metric: 2, merged_at: '2019-09-01T07:06:23.193Z' },
                        2: { metric: 3, merged_at: '2019-09-05T08:27:42.411Z' },
                      },
                      transformedData: [
                        [{ metric: 2, merged_at: '2019-09-01T07:06:23.193Z' }],
                        [{ metric: 3, merged_at: '2019-09-05T08:27:42.411Z' }],
                      ],
                    });
                  });

                  it('sets isLoading=false on the metric chart', () => {
                    expect(findScatterplotMetricChart().props('isLoading')).toBe(false);
                  });

                  it('passes non-empty chartData to the metric chart', () => {
                    expect(findScatterplotMetricChart().props('chartData')).not.toEqual([]);
                  });

                  describe('when the user changes the metric', () => {
                    beforeEach(async () => {
                      jest.spyOn(mockStore, 'dispatch');
                      findScatterplotMetricChart().vm.$emit('metricTypeChange', 'loc_per_commit');
                      await nextTick();
                    });

                    it('should call setMetricType  when `metricTypeChange` is emitted on the metric chart', () => {
                      expect(mockStore.dispatch).toHaveBeenCalledWith('charts/setMetricType', {
                        metricType: 'loc_per_commit',
                        chartKey: chartKeys.scatterplot,
                      });
                    });

                    it("should update the chart's y axis label", () => {
                      const scatterplot = findScatterplotMetricChart().findComponent(Scatterplot);
                      expect(scatterplot.props('yAxisTitle')).toBe('Number of LOCs per commit');
                    });
                  });
                });
              });
            });

            describe('MR table', () => {
              describe('when table is loading', () => {
                beforeEach(() => {
                  mockStore.dispatch('table/requestMergeRequests');
                });

                it('renders a loading indicator', () => {
                  expect(findMrTableSection().findComponent(GlLoadingIcon).exists()).toBe(true);
                });
              });

              describe('when table finished loading', () => {
                describe('and the table has data', () => {
                  beforeEach(() => {
                    mockStore.dispatch('table/receiveMergeRequestsSuccess', {
                      headers: {},
                      data: [{ id: 1, title: 'This is a test MR' }],
                    });
                  });

                  it('renders the MR table', () => {
                    expect(findMrTable().exists()).toBe(true);
                  });

                  it('doesn’t render a "no data" message', () => {
                    expect(findMrTableSection().findComponent(GlAlert).exists()).toBe(false);
                  });

                  it('should change the column metric', () => {
                    findMrTable().vm.$emit('columnMetricChange', 'time_to_first_comment');
                    const { calls } = tableActionSpies.setColumnMetric.mock;
                    expect(calls[calls.length - 1][1]).toBe('time_to_first_comment');
                  });

                  it('should change the page', () => {
                    const page = 2;
                    findMrTable().vm.$emit('pageChange', page);
                    const { calls } = tableActionSpies.setPage.mock;
                    expect(calls[calls.length - 1][1]).toBe(page);
                  });

                  describe('sort controls', () => {
                    it('renders the sort dropdown and button', () => {
                      expect(findSortFieldDropdown().exists()).toBe(true);
                      expect(findSortOrderToggle().exists()).toBe(true);
                    });

                    it('should change the sort field', () => {
                      findSortFieldDropdown()
                        .findAllComponents(GlDropdownItem)
                        .at(0)
                        .vm.$emit('click');

                      expect(tableActionSpies.setSortField).toHaveBeenCalled();
                    });

                    it('should toggle the sort order', () => {
                      findSortOrderToggle().vm.$emit('click');
                      expect(tableActionSpies.toggleSortOrder).toHaveBeenCalled();
                    });
                  });
                });

                describe("and the table doesn't have any data", () => {
                  beforeEach(() => {
                    mockStore.dispatch('table/receiveMergeRequestsSuccess', {
                      headers: {},
                      data: [],
                    });
                  });

                  it('renders a "no data" message', () => {
                    expect(findMrTableSection().findComponent(GlAlert).exists()).toBe(true);
                  });

                  it('doesn`t render the MR table', () => {
                    expect(findMrTable().exists()).not.toBe(true);
                  });

                  it('doesn`t render the sort dropdown and button', () => {
                    expect(findSortFieldDropdown().exists()).not.toBe(true);
                    expect(findSortOrderToggle().exists()).not.toBe(true);
                  });
                });
              });
            });
          });

          describe('and has no data', () => {
            beforeEach(() => {
              createComponent();
              mockStore.dispatch('charts/receiveChartDataSuccess', {
                chartKey: chartKeys.main,
                data: {},
              });
            });

            it('sets isLoading=false on the metric chart', () => {
              expect(findMainMetricChart().props('isLoading')).toBe(false);
            });

            it('passes an empty array as chartData to the metric chart', () => {
              expect(findMainMetricChart().props('chartData')).toEqual([]);
            });

            it('does not render any other charts', () => {
              expect(findSecondaryChartsSection().exists()).toBe(false);
            });

            it('does not render the MR table', () => {
              expect(findMrTableSortSection().exists()).toBe(false);
              expect(findMrTableSection().exists()).toBe(false);
            });
          });

          describe('with a server error', () => {
            beforeEach(() => {
              createComponent({
                options: {
                  stubs: {
                    'metric-chart': MetricChart,
                  },
                },
              });
              mockStore.dispatch('charts/receiveChartDataError', {
                chartKey: chartKeys.main,
                error: { response: { status: HTTP_STATUS_INTERNAL_SERVER_ERROR } },
              });
            });

            it('sets isLoading=false on the metric chart', () => {
              expect(findMainMetricChart().props('isLoading')).toBe(false);
            });

            it('passes a 500 status code to the metric chart', () => {
              expect(findMainMetricChart().props('errorCode')).toBe(
                HTTP_STATUS_INTERNAL_SERVER_ERROR,
              );
            });

            it('does not render any other charts', () => {
              expect(findSecondaryChartsSection().exists()).toBe(false);
            });

            it('renders the proper info message', () => {
              expect(findMainMetricChart().text()).toContain(
                'There is too much data to calculate. Please change your selection.',
              );
            });
          });
        });
      });
    });
  });

  describe('Url parameters', () => {
    const defaultFilters = {
      author_username: null,
      milestone_title: null,
      label_name: [],
      'not[author_username]': null,
      'not[milestone_title]': null,
      'not[label_name]': [],
    };

    const defaultResults = {
      project_id: null,
      group_id: null,
      merged_after: '2019-09-01T00:00:00Z',
      merged_before: '2019-09-02T23:59:59Z',
      'label_name[]': [],
      author_username: null,
      milestone_title: null,
      'not[author_username]': null,
      'not[milestone_title]': null,
      'not[label_name][]': [],
    };

    const shouldSetUrlParams = (result) => {
      const urlSync = wrapper.findComponent(UrlSync);
      expect(urlSync.props('query')).toStrictEqual(result);
    };

    beforeEach(() => {
      createComponent();
      mockStore.dispatch('filters/setInitialData', {
        skipFetch: true,
        data: {
          mergedAfter: new Date('2019-09-01'),
          mergedBefore: new Date('2019-09-02'),
        },
      });
    });

    it('sets the default url parameters', () => {
      shouldSetUrlParams(defaultResults);
    });

    describe('with filter parameters', () => {
      beforeEach(() => {
        createComponent();
        mockStore.dispatch('filters/setInitialData', {
          data: {
            mergedAfter: new Date('2019-09-01'),
            mergedBefore: new Date('2019-09-02'),
            ...mockFilters,
          },
        });
      });

      it('sets filter parameters', () => {
        shouldSetUrlParams({
          ...defaultResults,
          author_username: mockFilters.authorUsername,
          milestone_title: mockFilters.milestoneTitle,
          'label_name[]': mockFilters.labelName,
          'not[author_username]': mockFilters.notAuthorUsername,
          'not[milestone_title]': mockFilters.notMilestoneTitle,
          'not[label_name][]': mockFilters.notLabelName,
        });
      });
    });

    describe('with hideGroupDropDown=true', () => {
      beforeEach(() => {
        createComponent({ props: { hideGroupDropDown: true } });
        mockStore.dispatch('filters/setInitialData', {
          skipFetch: true,
          data: {
            mergedAfter: new Date('2019-09-01'),
            mergedBefore: new Date('2019-09-02'),
          },
        });

        mockStore.dispatch('filters/setGroupNamespace', 'earth-special-forces');
      });

      it('does not set the group_id', () => {
        shouldSetUrlParams({
          ...defaultResults,
        });
      });
    });

    describe('with a group selected', () => {
      beforeEach(() => {
        mockStore.dispatch('filters/setGroupNamespace', 'earth-special-forces');
      });

      it('sets the group_id', () => {
        shouldSetUrlParams({
          ...defaultResults,
          group_id: 'earth-special-forces',
        });
      });
    });

    describe('with a project selected', () => {
      beforeEach(() => {
        mockStore.dispatch('filters/setProjectPath', 'earth-special-forces/frieza-saga');
      });

      it('sets the project_id', () => {
        shouldSetUrlParams({
          ...defaultResults,
          project_id: 'earth-special-forces/frieza-saga',
        });
      });
    });

    describe.each`
      paramKey                  | resultKey                 | value
      ${'milestone_title'}      | ${'milestone_title'}      | ${'final-form'}
      ${'author_username'}      | ${'author_username'}      | ${'piccolo'}
      ${'label_name'}           | ${'label_name[]'}         | ${['who-will-win']}
      ${'not[milestone_title]'} | ${'not[milestone_title]'} | ${'not-final-form'}
      ${'not[author_username]'} | ${'not[author_username]'} | ${'not-piccolo'}
      ${'not[label_name]'}      | ${'not[label_name][]'}    | ${['not-who-will-win']}
    `('with the $paramKey filter set', ({ paramKey, resultKey, value }) => {
      beforeEach(() => {
        mockStore.dispatch('filters/setFilters', {
          ...defaultFilters,
          [paramKey]: value,
        });
      });

      it(`sets the '${resultKey}' url parameter`, () => {
        shouldSetUrlParams({
          ...defaultResults,
          [resultKey]: value,
        });
      });
    });
  });
});
