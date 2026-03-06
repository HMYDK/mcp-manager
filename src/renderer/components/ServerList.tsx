import React, { useState, useEffect } from 'react';
import ServerCard from './ServerCard';
import SearchBar from './SearchBar';
import AddServerModal from './AddServerModal';

interface MCPServer {
  id: string;
  name: string;
  packageName: string;
  status: string;
  enabledFor: any;
}

export default function ServerList() {
  const [servers, setServers] = useState<MCPServer[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [showAddModal, setShowAddModal] = useState(false);

  useEffect(() => {
    loadServers();
  }, []);

  const loadServers = async () => {
    const scanned = await (window as any).electronAPI.scanServers();
    setServers(scanned || []);
  };

  const filteredServers = servers.filter(s => 
    s.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    s.packageName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-4">
      <div className="flex gap-4">
        <SearchBar value={searchTerm} onChange={setSearchTerm} />
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Add Server
        </button>
      </div>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredServers.map(server => (
          <ServerCard key={server.id} server={server} onRefresh={loadServers} />
        ))}
      </div>
      {showAddModal && (
        <AddServerModal onClose={() => setShowAddModal(false)} onAdd={loadServers} />
      )}
    </div>
  );
}
