const reactRecommended = require('eslint-plugin-react/configs/recommended');

// npm i -g eslint eslint-plugin-simple-import-sort @babel/eslint-parser eslint-plugin-react @babel/core @babel/eslint-parser @babel/preset-react eslint-plugin-import

module.exports = [
  reactRecommended,
  {
    plugins: {
      'simple-import-sort': require('eslint-plugin-simple-import-sort'),
      react: require('eslint-plugin-react'),
      import: require('eslint-plugin-import'),
    },
    languageOptions: {
      parser: require('@babel/eslint-parser'),
      parserOptions: {
        requireConfigFile: false, // So @babel/eslint-parser doesn't need a .babelrc
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: {
          jsx: true,
        },
        babelOptions: {
          babelrc: false,
          configFile: false,
          presets: ['@babel/preset-react'],
        },
      },
    },
    rules: {
      'react/react-in-jsx-scope': 'off',
      'react/jsx-uses-react': 'error',
      'react/prop-types': 'off',

      'no-unused-vars': 'error',
      

      // "camelcase": "error",
      // "unicorn/prevent-abbreviations": ["error", {
      //   "checkProperties": false,
      //   "checkVariables": true,
      //   "checkFilenames": false
      // }],

      // https://github.com/lydell/eslint-plugin-simple-import-sort?tab=readme-ov-file#example-configuration
      'simple-import-sort/imports': [
        'warn',
        {
          groups: [
            // Node.js built-ins
            [
              '^node:.*',
              `^(${require('module').builtinModules.join('|')})(/.*)?$`,
            ],
            // React imports always first
            // ['^react$', '^react-dom$'],
            ['^react$', '^react-dom', '^@?\\w'],

            // Packages (third-party libraries)
            // ['^@?\\w'],
            // Imports starting with "components" or "shared"
            [
              'AppContext',
              'api',
              'components',
              'consts',
              'models',
              'shared',
              'utils',
              'views',
              'images',
            ].map((group) => `^${group}(/.*)?$`),
            // Relative imports (starting with . or ..)
            ['^\\.'],
          ],
        },
      ],
      'simple-import-sort/exports': 'warn',
      'import/first': 'error',
      'import/newline-after-import': 'error',
      'import/no-duplicates': 'error',
      'no-console': ['warn'],
      'import/order': [
        'error',
        {
          pathGroups: [
            {
              pattern: '{components/**,config/**,utils/**}',
              group: 'external',
              position: 'after',
            },
            // { pattern: './**', group: 'sibling', position: 'before' },
            // { pattern: '../**', group: 'parent', position: 'before' },
          ],
          // 'newlines-between': 'always',
          pathGroupsExcludedImportTypes: ['builtin'],
          // alphabetize: { order: 'asc', caseInsensitive: true },
        },
      ],
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
];
