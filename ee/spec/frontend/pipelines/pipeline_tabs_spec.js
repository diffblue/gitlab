import { createAppOptions } from 'ee/pipelines/pipeline_tabs';

const mockCeOptions = {
  foo: 'bar',
};

jest.mock('~/pipelines/pipeline_tabs', () => ({
  createAppOptions: () => mockCeOptions,
}));

describe('createAppOptions', () => {
  it('returns CE options', () => {
    expect(createAppOptions('selector', null)).toEqual(mockCeOptions);
  });
});
