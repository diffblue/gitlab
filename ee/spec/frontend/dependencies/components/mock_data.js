export const containerImagePath = {
  ancestors: null,
  topLevel: null,
  blobPath: 'test.link',
  path: 'container-image:nginx:1.17',
  image: 'nginx:1.17',
};

export const withoutPath = {
  ancestors: null,
  topLevel: null,
  blobPath: 'test.link',
  path: null,
};

export const withoutFilePath = {
  ancestors: null,
  topLevel: null,
  blobPath: null,
  path: 'package.json',
};

export const longPath = {
  ancestors: [
    {
      name: 'swell',
      version: '1.2',
    },
    {
      name: 'emmajsq',
      version: '10.11',
    },
    {
      name: 'zeb',
      version: '12.1',
    },
    {
      name: 'post',
      version: '2.5',
    },
    {
      name: 'core',
      version: '1.0',
    },
  ],
  topLevel: false,
  blobPath: 'test.link',
  path: 'package.json',
};

export const shortPath = {
  ancestors: [
    {
      name: 'swell',
      version: '1.2',
    },
    {
      name: 'emmajsq',
      version: '10.11',
    },
  ],
  topLevel: false,
  blobPath: 'test.link',
  path: 'package.json',
};

export const noPath = {
  ancestors: [],
  topLevel: false,
  blobPath: 'test.link',
  path: 'package.json',
};

export const topLevelPath = {
  ancestors: [],
  topLevel: true,
  blobPath: 'test.link',
  path: 'package.json',
};
