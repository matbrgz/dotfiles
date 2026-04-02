import React from 'react';
import { type ProgramManifest } from '@dotfiles/schema';
import { ProgramCard } from '@dotfiles/ui';

interface InventoryTabProps {
  registry: Record<string, ProgramManifest>;
  searchQuery: string;
  installing: Record<string, boolean>;
  onInstall: (id: string) => void;
  installedStatus: Record<string, boolean>;
}

export const InventoryTab: React.FC<InventoryTabProps> = ({ 
  registry, searchQuery, installing, onInstall, installedStatus
}) => {
  const categories = Array.from(new Set(Object.values(registry).map(p => p.category)));
  const filteredRegistry = Object.entries(registry).filter(([id, p]) => {
    const term = searchQuery.toLowerCase();
    return id.toLowerCase().includes(term) || p.name.toLowerCase().includes(term) || p.description.toLowerCase().includes(term);
  });

  return (
    <div className="flex-1 overflow-y-auto p-8 pb-64 custom-scrollbar">
      {categories.map(cat => {
        const catModules = filteredRegistry.filter(([_, p]) => p.category === cat);
        if (catModules.length === 0) return null;
        return (
          <section key={cat} className="mb-12">
            <h2 className="text-xs font-black text-zinc-500 uppercase tracking-[0.3em] mb-6 flex items-center gap-4">
              {cat}
              <div className="h-px bg-zinc-800 flex-1"></div>
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-4">
              {catModules.map(([id, prog]) => (
                <ProgramCard 
                  key={id}
                  title={prog.name}
                  description={prog.description}
                  category={prog.category}
                  onAction={() => onInstall(id)}
                  actionLabel={installing[id] ? "Processing..." : (installedStatus[id] ? "Reinstall" : "Deploy")}
                  status={installing[id] ? 'installing' : (installedStatus[id] ? 'success' : 'ready')}
                />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
};
