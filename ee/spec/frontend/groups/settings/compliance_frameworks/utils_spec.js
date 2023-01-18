import MockAdapter from 'axios-mock-adapter';
import * as Utils from 'ee/groups/settings/compliance_frameworks/utils';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';

const GET_RAW_FILE_ENDPOINT = /\/api\/(.*)\/projects\/bar%2Fbaz\/repository\/files\/foo\.ya?ml\/raw/;

describe('Utils', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('injectIdIntoEditPath', () => {
    it.each`
      path                          | id           | output
      ${'group/framework/abc/edit'} | ${1}         | ${''}
      ${'group/framework/id/edit'}  | ${undefined} | ${''}
      ${'group/framework/id/edit'}  | ${null}      | ${''}
      ${'group/framework/id/edit'}  | ${'abc'}     | ${''}
      ${'group/framework/id/edit'}  | ${'1'}       | ${'group/framework/1/edit'}
      ${'group/framework/id/edit'}  | ${1}         | ${'group/framework/1/edit'}
    `('should return $output when $path and $id are given', ({ path, id, output }) => {
      expect(Utils.injectIdIntoEditPath(path, id)).toStrictEqual(output);
    });
  });

  describe('initialiseFormData', () => {
    it('returns the initial form data object', () => {
      expect(Utils.initialiseFormData()).toStrictEqual({
        name: null,
        description: null,
        pipelineConfigurationFullPath: null,
        color: null,
      });
    });
  });

  describe('getSubmissionParams', () => {
    const baseFormData = {
      name: 'a',
      description: 'b',
      color: '#000',
    };

    it.each([true, false])(
      'should return the initial object when pipelineConfigurationFullPath is undefined and pipelineConfigurationFullPathEnabled is %s',
      (enabled) => {
        expect(Utils.getSubmissionParams(baseFormData, enabled)).toStrictEqual(baseFormData);
      },
    );

    it.each`
      pipelineConfigurationFullPath | pipelineConfigurationFullPathEnabled
      ${'a/b'}                      | ${true}
      ${null}                       | ${true}
      ${'a/b'}                      | ${false}
      ${null}                       | ${false}
    `(
      'should return the correct object when pipelineConfigurationFullPathEnabled is $pipelineConfigurationFullPathEnabled',
      ({ pipelineConfigurationFullPath, pipelineConfigurationFullPathEnabled }) => {
        const formData = Utils.getSubmissionParams(
          { ...baseFormData, pipelineConfigurationFullPath },
          pipelineConfigurationFullPathEnabled,
        );

        if (pipelineConfigurationFullPathEnabled) {
          expect(formData).toStrictEqual({ ...baseFormData, pipelineConfigurationFullPath });
        } else {
          expect(formData).toStrictEqual(baseFormData);
        }
      },
    );
  });

  describe('getPipelineConfigurationPathParts', () => {
    it.each`
      path                 | parts
      ${''}                | ${{ file: undefined, group: undefined, project: undefined }}
      ${'abc'}             | ${{ file: undefined, group: undefined, project: undefined }}
      ${'foo@bar/baz'}     | ${{ file: undefined, group: undefined, project: undefined }}
      ${'foo.pdf@bar/baz'} | ${{ file: undefined, group: undefined, project: undefined }}
      ${'foo.yml@bar/baz'} | ${{ file: 'foo.yml', group: 'bar', project: 'baz' }}
    `('should return the correct object when $path is given', ({ path, parts }) => {
      expect(Utils.getPipelineConfigurationPathParts(path)).toStrictEqual(parts);
    });
  });

  describe('validatePipelineConfirmationFormat', () => {
    it.each`
      path                  | valid
      ${null}               | ${false}
      ${''}                 | ${false}
      ${'abc'}              | ${false}
      ${'foo@bar/baz'}      | ${false}
      ${'foo.pdf@bar/baz'}  | ${false}
      ${'foo.yaml@bar/baz'} | ${true}
      ${'foo.yml@bar/baz'}  | ${true}
    `('should validate to $valid when path is $path', ({ path, valid }) => {
      expect(Utils.validatePipelineConfirmationFormat(path)).toBe(valid);
    });
  });

  describe('fetchPipelineConfigurationFileExists', () => {
    it.each`
      path                  | returns
      ${''}                 | ${false}
      ${'abc'}              | ${false}
      ${'foo@bar/baz'}      | ${false}
      ${'foo.pdf@bar/baz'}  | ${false}
      ${'foo.yaml@bar/baz'} | ${true}
      ${'foo.yml@bar/baz'}  | ${true}
    `('should return $returns when the path is $path', async ({ path, returns }) => {
      mock.onGet(GET_RAW_FILE_ENDPOINT).reply(returns ? HTTP_STATUS_OK : HTTP_STATUS_NOT_FOUND, {});

      expect(await Utils.fetchPipelineConfigurationFileExists(path)).toBe(returns);
    });

    it.each`
      response                  | returns
      ${HTTP_STATUS_OK}         | ${true}
      ${HTTP_STATUS_NO_CONTENT} | ${false}
      ${HTTP_STATUS_NOT_FOUND}  | ${false}
    `('should return $returns when the response is $response', async ({ response, returns }) => {
      mock.onGet(GET_RAW_FILE_ENDPOINT).reply(response, {});

      expect(await Utils.fetchPipelineConfigurationFileExists('foo.yml@bar/baz')).toBe(returns);
    });
  });
});
