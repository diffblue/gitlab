import { GlFilteredSearchTokenSegment } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';

import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchEpicsQuery from 'ee/vue_shared/components/filtered_search_bar/queries/search_epics.query.graphql';
import EpicToken from 'ee/vue_shared/components/filtered_search_bar/tokens/epic_token.vue';

import { mockEpicToken, mockEpics, mockGroupEpicsQueryResponse } from '../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

const defaultStubs = {
  Portal: true,
  GlFilteredSearchSuggestionList: {
    template: '<div></div>',
    methods: {
      getValue: () => '=',
    },
  },
};

describe('EpicToken', () => {
  let mock;
  let wrapper;
  let fakeApollo;

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  const epicQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupEpicsQueryResponse);
  const epicQueryHandlerError = jest.fn().mockRejectedValue({});

  function createComponent(options = {}, epicsQueryHandler = epicQueryHandlerSuccess) {
    fakeApollo = createMockApollo([[searchEpicsQuery, epicsQueryHandler]]);
    const {
      config = mockEpicToken,
      value = { data: '' },
      active = false,
      stubs = defaultStubs,
    } = options;
    return mount(EpicToken, {
      apolloProvider: fakeApollo,
      propsData: {
        config,
        value,
        active,
        cursorPosition: 'start',
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
      stubs,
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('methods', () => {
    describe('fetchEpicsBySearchTerm', () => {
      describe('when request is successful', () => {
        const searchTerm = 'foo';

        beforeEach(() => {
          wrapper = createComponent();
          findBaseToken().vm.$emit('fetch-suggestions', searchTerm);
          return waitForPromises();
        });

        it('calls fetchEpics with provided searchTerm param', () => {
          expect(epicQueryHandlerSuccess).toHaveBeenCalledWith({
            fullPath: expect.any(String),
            search: searchTerm,
          });
        });

        it('sets response to `epics`', () => {
          const mockEpicsData = mockGroupEpicsQueryResponse.data.group.epics.nodes;
          expect(findBaseToken().props('suggestions')).toEqual(mockEpicsData);
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });

      describe('when request is unsuccessful', () => {
        beforeEach(() => {
          wrapper = createComponent({}, epicQueryHandlerError);
          findBaseToken().vm.$emit('fetch-suggestions');
          return waitForPromises();
        });

        it('calls `createAlert` with alert error message', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'There was a problem fetching epics.',
          });
        });

        it('sets `loading` to false when request completes', () => {
          expect(findBaseToken().props('suggestionsLoading')).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    const getTokenValueEl = () => wrapper.findAllComponents(GlFilteredSearchTokenSegment).at(2);

    beforeEach(async () => {
      wrapper = createComponent({
        value: { data: `${mockEpics[0].title}::&${mockEpics[0].iid}` },
        data: { epics: mockEpics },
      });

      await nextTick();
    });

    it('renders BaseToken component', () => {
      expect(findBaseToken().exists()).toBe(true);
    });

    it('renders token item when value is selected', () => {
      const tokenSegments = wrapper.findAllComponents(GlFilteredSearchTokenSegment);

      expect(tokenSegments).toHaveLength(3);
      expect(tokenSegments.at(2).text()).toBe(`${mockEpics[0].title}::&${mockEpics[0].iid}`);
    });

    it.each`
      value                                            | valueType   | tokenValueString
      ${`${mockEpics[0].title}::&${mockEpics[0].iid}`} | ${'string'} | ${`${mockEpics[0].title}::&${mockEpics[0].iid}`}
      ${`${mockEpics[1].title}::&${mockEpics[1].iid}`} | ${'number'} | ${`${mockEpics[1].title}::&${mockEpics[1].iid}`}
    `('renders token item when selection is a $valueType', async ({ value, tokenValueString }) => {
      wrapper = createComponent({
        value: { data: value },
      });

      await nextTick();

      expect(getTokenValueEl().text()).toBe(tokenValueString);
    });
  });
});
