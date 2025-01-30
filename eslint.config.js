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

      // https://github.com/lydell/eslint-plugin-simple-import-sort?tab=readme-ov-file#example-configuration
      'simple-import-sort/imports': 'error',
      'simple-import-sort/exports': 'error',
      'import/first': 'error',
      'import/newline-after-import': 'error',
      'import/no-duplicates': 'error',
    },
    settings: {
      react: {
        version: 'detect',
      },
    },
  },
];
