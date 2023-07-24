import listModule from 'ee/dependencies/store/modules/list';
import {
  addListType,
  extractGroupNamespace,
  filterPathBySearchTerm,
} from 'ee/dependencies/store/utils';

const mockModule = { mock: true };
jest.mock('ee/dependencies/store/modules/list', () => ({
  // `__esModule: true` is required when mocking modules with default exports:
  // https://jestjs.io/docs/en/jest-object#jestmockmodulename-factory-options
  __esModule: true,
  default: jest.fn(() => mockModule),
}));

describe('Dependencies store utils', () => {
  describe('addListType', () => {
    it('calls the correct store methods', () => {
      const store = {
        dispatch: jest.fn(),
        registerModule: jest.fn(),
      };

      const listType = {
        namespace: 'foo',
        initialState: { bar: true },
      };

      addListType(store, listType);

      expect(listModule).toHaveBeenCalled();
      expect(store.registerModule.mock.calls).toEqual([[listType.namespace, mockModule]]);
      expect(store.dispatch.mock.calls).toEqual([
        ['addListType', listType],
        [`${listType.namespace}/setInitialState`, listType.initialState],
      ]);
    });
  });

  describe('extractGroupNamespace', () => {
    it('returns empty string when source endpoint does not match', () => {
      const invalidEndpoint = '/my-group/my-project/-/dependencies.json';
      expect(extractGroupNamespace(invalidEndpoint)).toBe('');
    });

    it('returns group namespace for a valid endpoint', () => {
      const validEndpoint = '/groups/my-group/-/dependencies.json';
      expect(extractGroupNamespace(validEndpoint)).toBe('my-group');
    });
  });

  describe('filterPathBySearchTerm', () => {
    const data = [
      {
        location: {
          path: 'path',
        },
      },
      {
        location: {
          path: 'file',
        },
      },
    ];

    it('returns all locations if search parameter is empty', () => {
      expect(filterPathBySearchTerm(data, '')).toBe(data);
    });

    it('returns only matching locations', () => {
      expect(filterPathBySearchTerm(data, 'pat')).toStrictEqual([data[0]]);
    });
  });
});
