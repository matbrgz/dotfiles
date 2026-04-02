import React from 'react';
import { type UserSettings, type ProgramManifest, type DotfileManifest } from '@dotfiles/schema';
import { User, GitFork, HardDrive, Fingerprint } from 'lucide-react';

interface ProfileTabProps {
  settings: UserSettings;
  registry: Record<string, ProgramManifest>;
  dotfiles: Record<string, DotfileManifest>;
  osInfo: { os: string; platform: string };
}

export const ProfileTab: React.FC<ProfileTabProps> = ({ 
  settings, registry, dotfiles, osInfo 
}) => {
  return (
    <div className="flex-1 overflow-y-auto p-8 pb-64 custom-scrollbar">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-5xl">
        
        <div className="space-y-8">
          <div className="bg-zinc-950 border border-zinc-900 p-8 relative overflow-hidden group">
            <div className="absolute top-0 right-0 w-32 h-32 bg-cyan-500/5 rotate-45 translate-x-16 -translate-y-16"></div>
            <User className="w-12 h-12 text-cyan-500 mb-6" />
            <h2 className="text-3xl font-black text-white tracking-tighter uppercase mb-1">{settings.personal.name}</h2>
            <p className="text-xs text-zinc-500 font-bold uppercase tracking-[0.2em]">{settings.personal.email}</p>
            
            <div className="mt-8 flex items-center gap-4 text-xs font-bold">
              <div className="flex items-center gap-2 text-zinc-400">
                <GitFork className="w-4 h-4" />
                <span>@{settings.personal.githubuser}</span>
              </div>
              <div className="w-1 h-1 bg-zinc-800 rounded-full"></div>
              <div className="text-cyan-500 uppercase tracking-widest">Lvl_99_Developer</div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-zinc-900/30 border border-zinc-900 p-6">
              <p className="text-[9px] text-zinc-600 font-black uppercase tracking-widest mb-2">Modules_Available</p>
              <p className="text-3xl font-black text-white italic">{Object.keys(registry).length}</p>
            </div>
            <div className="bg-zinc-900/30 border border-zinc-900 p-6">
              <p className="text-[9px] text-zinc-600 font-black uppercase tracking-widest mb-2">Dotfiles_Managed</p>
              <p className="text-3xl font-black text-white italic">{Object.keys(dotfiles).length}</p>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div className="bg-zinc-950 border border-zinc-900 p-6">
            <div className="flex items-center gap-3 mb-6">
              <HardDrive className="w-4 h-4 text-cyan-500" />
              <h3 className="text-xs font-black text-white uppercase tracking-widest">Environment_Telemetry</h3>
            </div>
            
            <div className="space-y-4">
              {[
                { label: 'OS_KERNEL', val: osInfo.os },
                { label: 'CPU_ARCH', val: osInfo.platform },
                { label: 'NODE_RT', val: 'v24.13.0' },
                { label: 'TAURI_VER', val: 'v1.8.3' }
              ].map(stat => (
                <div key={stat.label} className="flex justify-between items-center border-b border-zinc-900/50 pb-2">
                  <span className="text-[10px] font-bold text-zinc-600 uppercase">{stat.label}</span>
                  <span className="text-[10px] font-mono text-cyan-400 font-bold uppercase">{stat.val}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="p-6 border border-cyan-500/10 bg-cyan-500/5">
            <div className="flex items-center gap-3 mb-4">
              <Fingerprint className="w-4 h-4 text-cyan-500" />
              <h3 className="text-xs font-black text-white uppercase tracking-widest">Security_Token</h3>
            </div>
            <p className="text-[9px] text-zinc-500 font-bold leading-relaxed uppercase">
              Your session is encrypted and local. All configuration changes are committed directly to your workspace repository.
            </p>
          </div>
        </div>

      </div>
    </div>
  );
};
