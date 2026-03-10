const os = require('os');
const path = require('path');

function buildOfficialTools(workspaceRoot = process.cwd()) {
  const home = os.homedir();

  return [
    {
      id: 'codex-cli',
      name: 'Codex CLI',
      cliCommand: 'codex',
      format: 'codex_toml',
      scope: 'user',
      officialPath: path.join(home, '.codex', 'config.toml'),
      configPath: path.join(home, '.codex', 'config.toml'),
      pathLocked: true,
      docsUrl: 'https://platform.openai.com/docs/docs-mcp',
      verifyArgs: ['mcp', 'list'],
    },
    {
      id: 'claude-code',
      name: 'Claude Code',
      cliCommand: 'claude',
      format: 'claude_project_json',
      scope: 'project',
      officialPath: path.join(workspaceRoot, '.mcp.json'),
      configPath: path.join(workspaceRoot, '.mcp.json'),
      pathLocked: true,
      docsUrl: 'https://code.claude.com/docs/en/mcp',
      verifyArgs: ['mcp', 'list'],
    },
    {
      id: 'gemini-cli',
      name: 'Gemini CLI',
      cliCommand: 'gemini',
      format: 'gemini_project_json',
      scope: 'project',
      officialPath: path.join(workspaceRoot, '.gemini', 'settings.json'),
      configPath: path.join(workspaceRoot, '.gemini', 'settings.json'),
      pathLocked: true,
      docsUrl: 'https://google-gemini.github.io/gemini-cli/docs/tools/mcp-server.html',
      verifyArgs: ['mcp', 'list', '--scope', 'project'],
    },
  ];
}

module.exports = {
  buildOfficialTools,
};
