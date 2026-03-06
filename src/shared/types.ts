// MCP Server data model
export interface MCPServer {
  id: string;
  name: string;
  packageName: string;
  packageType: 'npm' | 'pip';
  version?: string;
  installPath?: string;
  status: 'installed' | 'running' | 'stopped' | 'error';
  config: Record<string, any>;
  enabledFor: {
    claudeCode: boolean;
    geminiCli: boolean;
    qoderCli: boolean;
  };
  createdAt: string;
  updatedAt: string;
}

export interface UserPreferences {
  theme: 'dark' | 'light' | 'system';
  autoCheckUpdates: boolean;
  defaultCLI: string;
}

export interface ServerStatus {
  status: 'running' | 'stopped' | 'error';
  pid?: number;
  error?: string;
}

export interface BuiltinServer {
  name: string;
  packageName: string;
  packageType: 'npm' | 'pip';
  description: string;
  category: string;
}
