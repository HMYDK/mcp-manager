import React from 'react';

interface ServerCardProps {
  server: {
    id: string;
    name: string;
    packageName: string;
    status: string;
    enabledFor: {
      claudeCode: boolean;
      geminiCli: boolean;
      qoderCli: boolean;
    };
  };
  onRefresh: () => void;
}

export default function ServerCard({ server, onRefresh }: ServerCardProps) {
  const statusColors: Record<string, string> = {
    running: 'bg-green-500',
    stopped: 'bg-gray-500',
    error: 'bg-red-500',
    installed: 'bg-blue-500',
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-4">
      <div className="flex justify-between items-start mb-2">
        <h3 className="text-lg font-semibold">{server.name}</h3>
        <span className={`px-2 py-1 rounded text-xs text-white ${statusColors[server.status] || 'bg-gray-500'}`}>
          {server.status}
        </span>
      </div>
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">{server.packageName}</p>
      <div className="space-y-2">
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={server.enabledFor.claudeCode} readOnly />
          <span className="text-sm">Claude Code</span>
        </label>
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={server.enabledFor.geminiCli} readOnly />
          <span className="text-sm">Gemini CLI</span>
        </label>
        <label className="flex items-center gap-2">
          <input type="checkbox" checked={server.enabledFor.qoderCli} readOnly />
          <span className="text-sm">QoderCLI</span>
        </label>
      </div>
    </div>
  );
}
