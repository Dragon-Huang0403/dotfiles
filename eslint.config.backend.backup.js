const importPlugin = require('eslint-plugin-import');
const unusedImports = require('eslint-plugin-unused-imports');
const prettierPlugin = require('eslint-plugin-prettier');
const prettierConfig = require('eslint-config-prettier');
const typescriptEslintPlugin = require('@typescript-eslint/eslint-plugin');
const typescriptParser = require('@typescript-eslint/parser');
const globals = require('globals');
const fs = require('fs');
const path = require('path');

// Parse tsconfig.json to get path mappings
const tsconfigPath = path.join(__dirname, 'tsconfig.json');
const tsconfig = JSON.parse(fs.readFileSync(tsconfigPath, 'utf8'));
const tsconfigPaths = tsconfig.compilerOptions?.paths ?? {};

// Extract internal module names from tsconfig paths, excluding test helpers
const internalModules = Object.keys(tsconfigPaths)
  .map((key) => key.replace('/*', ''))
  .filter((value, index, self) => self.indexOf(value) === index) // Remove duplicates
  .sort();

// Create pattern for import/order pathGroups
const importOrderPattern = `{${internalModules
  .map((m) => `${m},${m}/**`)
  .join(',')}}`;

module.exports = [
  // Prettier config to disable conflicting rules
  prettierConfig,
  {
    files: ['src/**/*.js'],
    settings: {
      'import/resolver': {
        typescript: {
          project: './tsconfig.json',
        },
      },
    },
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: 'module',
      globals: {
        ...globals.node,
      },
    },
    plugins: {
      import: importPlugin,
      'unused-imports': unusedImports,
      prettier: prettierPlugin,
    },
    rules: {
      // CommonJS detection
      'import/no-commonjs': [
        'error',
        {
          allowRequire: false,
          allowConditionalRequire: false,
          allowPrimitiveModules: false,
        },
      ],

      // Import organization
      'import/order': [
        'error',
        {
          groups: [
            'builtin', // Node.js built-in modules
            'external', // External packages
            'internal', // Internal aliases/paths
            'parent', // Parent directory imports
            'sibling', // Same directory imports
            'index', // Index file imports
          ],
          pathGroups: [
            {
              pattern: importOrderPattern,
              group: 'internal',
              position: 'after',
            },
          ],
          pathGroupsExcludedImportTypes: ['builtin'],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],

      // Unused imports detection
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
        },
      ],

      // Other import rules
      'import/first': 'error', // All imports must be at the top of the file
      'import/exports-last': 'error', // All exports at the bottom
      'import/newline-after-import': ['error', { count: 1 }], // Require newline after imports
      'import/no-duplicates': 'error',
      'import/no-unresolved': 'error',
      'import/named': 'error',
      'import/default': 'error',
      'import/namespace': 'error',

      // General rules
      'no-unused-vars': 'off', // Turned off - using unused-imports/no-unused-vars instead
      'no-undef': 'error', // catches undefined variables
      'no-constant-binary-expression': 'warn', // catches `x || y ?? z`, `x === []`, etc.
      'no-self-compare': 'warn', // catches `x === x`

      // Prettier integration
      'prettier/prettier': 'error',
    },
  },
  {
    // TypeScript files configuration
    files: ['src/**/*.ts', 'testing/**/*.ts'],
    languageOptions: {
      parser: typescriptParser,
      parserOptions: {
        ecmaVersion: 2020,
        sourceType: 'module',
        project: './tsconfig.json',
      },
    },
    plugins: {
      '@typescript-eslint': typescriptEslintPlugin,
      import: importPlugin,
      'unused-imports': unusedImports,
      prettier: prettierPlugin,
    },
    settings: {
      'import/resolver': {
        typescript: {
          project: './tsconfig.json',
        },
      },
    },
    rules: {
      // TypeScript-specific rules
      '@typescript-eslint/no-unused-vars': 'off', // Using unused-imports instead
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/explicit-module-boundary-types': 'off',

      // Import rules (same as JS)
      'import/no-commonjs': [
        'error',
        {
          allowRequire: false,
          allowConditionalRequire: false,
          allowPrimitiveModules: false,
        },
      ],
      'import/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            'parent',
            'sibling',
            'index',
          ],
          pathGroups: [
            {
              pattern: importOrderPattern,
              group: 'internal',
              position: 'after',
            },
          ],
          pathGroupsExcludedImportTypes: ['builtin'],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
        },
      ],
      'import/first': 'error', // All imports must be at the top of the file
      'import/exports-last': 'error', // All exports at the bottom
      'import/newline-after-import': ['error', { count: 1 }], // Require newline after imports
      'import/no-duplicates': 'error',
      'import/no-unresolved': 'error',
      'import/named': 'error',
      'import/default': 'error',
      'import/namespace': 'error',
      'no-constant-binary-expression': 'warn',
      'no-self-compare': 'warn',
      'prettier/prettier': 'error',
    },
  },
  {
    // Test files configuration with Jest globals
    files: ['testing/**/*.{js,ts}', '**/*.test.{js,ts}', '**/*.spec.{js,ts}'],
    settings: {
      'import/resolver': {
        typescript: {
          project: './tsconfig.json',
        },
      },
    },
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: 'module',
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    plugins: {
      import: importPlugin,
      'unused-imports': unusedImports,
      prettier: prettierPlugin,
    },
    rules: {
      'import/no-commonjs': 'off', // Allow CommonJS in tests during migration
      'unused-imports/no-unused-imports': 'error',
      'unused-imports/no-unused-vars': [
        'warn',
        {
          vars: 'all',
          varsIgnorePattern: '^_',
          args: 'after-used',
          argsIgnorePattern: '^_',
        },
      ],
      'import/order': [
        'error',
        {
          groups: [
            'builtin',
            'external',
            'internal',
            'parent',
            'sibling',
            'index',
          ],
          pathGroups: [
            {
              pattern: importOrderPattern,
              group: 'internal',
              position: 'after',
            },
          ],
          pathGroupsExcludedImportTypes: ['builtin'],
          'newlines-between': 'always',
          alphabetize: {
            order: 'asc',
            caseInsensitive: true,
          },
        },
      ],
      'import/first': 'error', // All imports must be at the top of the file
      'import/exports-last': 'error', // All exports at the bottom
      'import/newline-after-import': ['error', { count: 1 }], // Require newline after imports
      'import/no-duplicates': 'error',
      'import/no-unresolved': 'error',
      'import/named': 'error',
      'import/default': 'error',
      'import/namespace': 'error',
      'no-unused-vars': 'off', // Turned off - using unused-imports/no-unused-vars instead
      'no-undef': 'error',
      'no-constant-binary-expression': 'warn',
      'no-self-compare': 'warn',

      // Prettier integration
      'prettier/prettier': 'error',
    },
  },
  {
    // Allow CommonJS in specific directories
    files: [
      'db/migrations/**/*.js',
      'db/seeds/**/*.js',
      'db/*.js',
      'scripts/**/*.js',
      'eslint.config.js',
      'jest.config.js',
    ],
    rules: {
      'import/no-commonjs': 'off',
    },
  },
];
