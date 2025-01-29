const simpleImportSort = require('eslint-plugin-simple-import-sort');
// const babelParser = require('@babel/eslint-parser');

// npm i -g eslint eslint-plugin-simple-import-sort @babel/eslint-parser

// eslint.config.js
module.exports = {
  // extends: ['airbnb'],
  plugins: { 'simple-import-sort': simpleImportSort },
  // languageOptions: {
  //   parser: babelParser,
  //   parserOptions: {
  //     requireConfigFile: false, // So @babel/eslint-parser doesn't need a .babelrc
  //     ecmaVersion: 'latest',
  //     sourceType: 'module',
  //     ecmaFeatures: {
  //       jsx: true,
  //     },
  //     babelOptions: {
  //       presets: ['@babel/preset-react'],
  //     },
  //   },
  // },
  rules: {
    'no-unused-vars': 'error',
    'simple-import-sort/imports': [
      'error',
      {
        groups: [
          // 1. Side effect imports at the start. For me this is important because I want to import reset.css and global styles at the top of my main file.
          ['^\\u0000'],
          // 2. `react` and packages: Things that start with a letter (or digit or underscore), or `@` followed by a letter.
          ['^react$', '^@?\\w'],
          // 3. Absolute imports and other imports such as Vue-style `@/foo`.
          // Anything not matched in another group. (also relative imports starting with "../")
          ['^@', '^'],
          // 4. relative imports from same folder "./" (I like to have them grouped together)
          ['^\\./'],
          // 5. style module imports always come last, this helps to avoid CSS order issues
          ['^.+\\.(module.css|module.scss)$'],
          // 6. media imports
          ['^.+\\.(gif|png|svg|jpg)$'],
        ],
      },
    ],
  },
};
