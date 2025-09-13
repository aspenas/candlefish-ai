module.exports = {
  branches: [
    'main',
    { name: 'beta', prerelease: true },
    { name: 'alpha', prerelease: true },
    { name: 'develop', prerelease: 'dev' }
  ],
  plugins: [
    // Analyze commits to determine version bump
    ['@semantic-release/commit-analyzer', {
      preset: 'angular',
      releaseRules: [
        { type: 'feat', release: 'minor' },
        { type: 'fix', release: 'patch' },
        { type: 'perf', release: 'patch' },
        { type: 'docs', scope: 'README', release: 'patch' },
        { breaking: true, release: 'major' },
        { revert: true, release: 'patch' }
      ]
    }],
    
    // Generate release notes
    ['@semantic-release/release-notes-generator', {
      preset: 'angular',
      writerOpts: {
        commitsSort: ['subject', 'scope']
      }
    }],
    
    // Update CHANGELOG.md
    ['@semantic-release/changelog', {
      changelogFile: 'CHANGELOG.md',
      changelogTitle: '# Candlefish AI Changelog\n\nAll notable changes to this project will be documented in this file.'
    }],
    
    // Update version in package.json files
    ['@semantic-release/exec', {
      prepareCmd: 'node scripts/update-versions.js ${nextRelease.version}'
    }],
    
    // Commit changes
    ['@semantic-release/git', {
      assets: [
        'CHANGELOG.md',
        'package.json',
        'package-lock.json',
        'pyproject.toml',
        'projects/*/package.json',
        'helm/*/Chart.yaml'
      ],
      message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}'
    }],
    
    // Create GitHub release
    ['@semantic-release/github', {
      successComment: false,
      failComment: false,
      labels: ['release'],
      releasedLabels: ['released']
    }]
  ]
};