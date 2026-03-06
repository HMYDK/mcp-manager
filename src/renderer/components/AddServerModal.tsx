import React, { useState } from 'react';

interface AddServerModalProps {
  onClose: () => void;
  onAdd: () => void;
}

export default function AddServerModal({ onClose, onAdd }: AddServerModalProps) {
  const [name, setName] = useState('');
  const [packageName, setPackageName] = useState('');
  const [packageType, setPackageType] = useState<'npm' | 'pip'>('npm');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // In a real app, this would call the API to add the server
    await (window as any).electronAPI.scanServers();
    onAdd();
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md">
        <h2 className="text-xl font-bold mb-4">Add MCP Server</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Display Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 border rounded bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Package Name</label>
            <input
              type="text"
              value={packageName}
              onChange={(e) => setPackageName(e.target.value)}
              className="w-full px-3 py-2 border rounded bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600"
              placeholder="@org/package or package-name"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Package Type</label>
            <select
              value={packageType}
              onChange={(e) => setPackageType(e.target.value as 'npm' | 'pip')}
              className="w-full px-3 py-2 border rounded bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600"
            >
              <option value="npm">npm</option>
              <option value="pip">pip</option>
            </select>
          </div>
          <div className="flex gap-2 justify-end">
            <button type="button" onClick={onClose} className="px-4 py-2 border rounded hover:bg-gray-100 dark:hover:bg-gray-700">
              Cancel
            </button>
            <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
              Add
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
