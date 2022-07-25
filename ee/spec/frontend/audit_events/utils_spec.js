import {
  getTypeFromEntityType,
  getEntityTypeFromType,
  parseAuditEventSearchQuery,
  createAuditEventSearchQuery,
  mapAllMutationErrors,
  mapItemHeadersToFormData,
} from 'ee/audit_events/utils';
import { destinationDeleteMutationPopulator, mockExternalDestinationHeader } from './mock_data';

describe('Audit Event Utils', () => {
  describe('getTypeFromEntityType', () => {
    it('returns the correct type when given a valid entity type', () => {
      expect(getTypeFromEntityType('User')).toEqual('user');
    });

    it('returns `undefined` when given an invalid entity type', () => {
      expect(getTypeFromEntityType('ABCDEF')).toBeUndefined();
    });
  });

  describe('getEntityTypeFromType', () => {
    it('returns the correct entity type when given a valid type', () => {
      expect(getEntityTypeFromType('member')).toEqual('Author');
    });

    it('returns `undefined` when given an invalid type', () => {
      expect(getTypeFromEntityType('abcdef')).toBeUndefined();
    });
  });

  describe('parseAuditEventSearchQuery', () => {
    it('returns a query object with parsed date values', () => {
      const input = {
        created_after: '2020-03-13',
        created_before: '2020-04-13',
        sortBy: 'created_asc',
      };

      expect(parseAuditEventSearchQuery(input)).toMatchObject({
        created_after: new Date('2020-03-13'),
        created_before: new Date('2020-04-13'),
        sortBy: 'created_asc',
      });
    });
  });

  describe('createAuditEventSearchQuery', () => {
    const createFilterParams = (type, data) => ({
      filterValue: [{ type, value: { data, operator: '=' } }],
      startDate: new Date('2020-03-13'),
      endDate: new Date('2020-04-13'),
      sortBy: 'bar',
    });

    it.each`
      type         | entity_type  | data       | entity_id | entity_username | author_username
      ${'user'}    | ${'User'}    | ${'@root'} | ${null}   | ${'root'}       | ${null}
      ${'member'}  | ${'Author'}  | ${'@root'} | ${null}   | ${null}         | ${'root'}
      ${'project'} | ${'Project'} | ${'1'}     | ${'1'}    | ${null}         | ${null}
      ${'group'}   | ${'Group'}   | ${'1'}     | ${'1'}    | ${null}         | ${null}
    `(
      'returns a query object with remapped keys and stringified dates for type $type',
      ({ type, entity_type, data, entity_id, entity_username, author_username }) => {
        const input = createFilterParams(type, data);

        expect(createAuditEventSearchQuery(input)).toEqual({
          entity_id,
          entity_username,
          author_username,
          entity_type,
          created_after: '2020-03-13',
          created_before: '2020-04-13',
          sort: 'bar',
          page: null,
        });
      },
    );
  });

  describe('mapItemHeadersToFormData', () => {
    const header1 = mockExternalDestinationHeader();
    const header2 = mockExternalDestinationHeader();
    const header3 = mockExternalDestinationHeader();

    it.each([{}, { headers: {} }, { headers: { nodes: [] } }])(
      'returns an empty array when there are no headers',
      (item) => {
        expect(mapItemHeadersToFormData(item)).toEqual([]);
      },
    );

    it('returns the formatted headers', () => {
      expect(mapItemHeadersToFormData({ headers: { nodes: [header1, header2] } })).toStrictEqual([
        {
          id: header1.id,
          name: header1.key,
          value: header1.value,
          active: true,
          disabled: false,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
        {
          id: header2.id,
          name: header2.key,
          value: header2.value,
          active: true,
          disabled: false,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
      ]);
    });

    it('applies the settings to each header when given', () => {
      expect(
        mapItemHeadersToFormData({ headers: { nodes: [header1, header2] } }, { disabled: true }),
      ).toStrictEqual([
        {
          id: header1.id,
          name: header1.key,
          value: header1.value,
          active: true,
          disabled: true,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
        {
          id: header2.id,
          name: header2.key,
          value: header2.value,
          active: true,
          disabled: true,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
      ]);
    });

    it('sorts the headers by their ID', () => {
      expect(
        mapItemHeadersToFormData({ headers: { nodes: [header3, header1, header2] } }),
      ).toStrictEqual([
        {
          id: header1.id,
          name: header1.key,
          value: header1.value,
          active: true,
          disabled: false,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
        {
          id: header2.id,
          name: header2.key,
          value: header2.value,
          active: true,
          disabled: false,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
        {
          id: header3.id,
          name: header3.key,
          value: header3.value,
          active: true,
          disabled: false,
          deletionDisabled: false,
          validationErrors: { name: '' },
        },
      ]);
    });
  });

  describe('mapAllMutationErrors', () => {
    it('returns an empty array when there are no errors', async () => {
      const mutations = [
        Promise.resolve(destinationDeleteMutationPopulator()),
        Promise.resolve(destinationDeleteMutationPopulator()),
      ];

      await expect(
        mapAllMutationErrors(mutations, 'externalAuditEventDestinationDestroy'),
      ).resolves.toStrictEqual([]);
    });

    it('throws any rejected errors', async () => {
      const error = new Error('rejected error');
      const mutations = [
        Promise.reject(error),
        Promise.resolve(destinationDeleteMutationPopulator()),
      ];

      await expect(
        mapAllMutationErrors(mutations, 'externalAuditEventDestinationDestroy'),
      ).rejects.toThrow(error);
    });

    it('returns the errors found within each mutations errors property', async () => {
      const errors = ['Validation error 1', 'Validation error 2', 'Validation error 3'];
      const mutations = [
        Promise.resolve(destinationDeleteMutationPopulator(errors)),
        Promise.resolve(destinationDeleteMutationPopulator()),
      ];

      await expect(
        mapAllMutationErrors(mutations, 'externalAuditEventDestinationDestroy'),
      ).resolves.toStrictEqual(errors);
    });
  });
});
