import React from 'react';
import { type UserSettings } from '@dotfiles/schema';
import { User, ShieldCheck, Save } from 'lucide-react';

interface SettingsTabProps {
  settings: UserSettings;
  setSettings: (settings: UserSettings) => void;
  onSave: () => void;
  isSaving: boolean;
}

export const SettingsTab: React.FC<SettingsTabProps> = ({ 
  settings, setSettings, onSave, isSaving 
}) => {
  return (
    <div className="flex-1 overflow-y-auto p-8 pb-64 custom-scrollbar">
      <div className="max-w-3xl space-y-12">
        <section>
          <div className="flex items-center gap-3 mb-8">
            <User className="w-5 h-5 text-cyan-500" />
            <h2 className="text-lg font-black text-white uppercase tracking-tight">Identity_Data</h2>
          </div>
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-2">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">Full_Name</label>
              <input type="text" value={settings.personal.name} onChange={(e) => setSettings({...settings, personal: {...settings.personal, name: e.target.value}})} className="w-full bg-zinc-950 border border-zinc-900 p-3 text-xs font-bold text-cyan-400 focus:outline-none focus:border-cyan-500/50" />
            </div>
            <div className="space-y-2">
              <label className="text-[10px] font-black text-zinc-600 uppercase tracking-widest">Email_Uplink</label>
              <input type="email" value={settings.personal.email} onChange={(e) => setSettings({...settings, personal: {...settings.personal, email: e.target.value}})} className="w-full bg-zinc-950 border border-zinc-900 p-3 text-xs font-bold text-cyan-400 focus:outline-none focus:border-cyan-500/50" />
            </div>
          </div>
        </section>

        <section>
          <div className="flex items-center gap-3 mb-8 pt-8 border-t border-zinc-900">
            <ShieldCheck className="w-5 h-5 text-cyan-500" />
            <h2 className="text-lg font-black text-white uppercase tracking-tight">System_Behavior</h2>
          </div>
          <div className="space-y-6">
            {[
              { id: 'debug_mode', label: 'DEBUG_ANALYTICS', desc: 'Verbose output for core processes' },
              { id: 'backup_configs', label: 'AUTO_BACKUP', desc: 'Force backup before overwriting dotfiles' },
              { id: 'purge_mode', label: 'PURGE_PROTOCOL', desc: 'Remove old configurations during sync' }
            ].map(opt => (
              <div key={opt.id} className="flex items-center justify-between p-4 bg-zinc-950/50 border border-zinc-900 group hover:border-cyan-500/20 transition-colors">
                <div>
                  <p className="text-[11px] font-black text-white uppercase tracking-wider">{opt.label}</p>
                  <p className="text-[9px] text-zinc-600 font-bold uppercase leading-none mt-1">{opt.desc}</p>
                </div>
                <button onClick={() => setSettings({ ...settings, system: { ...settings.system, behavior: { ...settings.system.behavior, [opt.id]: !((settings.system.behavior as any)[opt.id]) } } })} className={`w-12 h-6 border transition-all relative ${ (settings.system.behavior as any)[opt.id] ? 'bg-cyan-500/20 border-cyan-500' : 'bg-zinc-900 border-zinc-800' }`}>
                  <div className={`absolute top-1 w-4 h-4 transition-all ${ (settings.system.behavior as any)[opt.id] ? 'right-1 bg-cyan-400' : 'left-1 bg-zinc-700' }`}></div>
                </button>
              </div>
            ))}
          </div>
        </section>

        <div className="pt-8">
          <button onClick={onSave} disabled={isSaving} className={`flex items-center justify-center gap-3 w-full py-4 border text-xs font-black uppercase tracking-[0.3em] transition-all ${isSaving ? 'bg-zinc-900 border-zinc-800 text-zinc-600 cursor-wait' : 'bg-white text-black border-white hover:bg-transparent hover:text-white'}`}>
            <Save className="w-4 h-4" />
            {isSaving ? 'PERSISTING_DATA...' : 'COMMIT_CONFIGURATIONS'}
          </button>
        </div>
      </div>
    </div>
  );
};
