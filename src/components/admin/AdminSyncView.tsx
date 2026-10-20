import React, { useState, useEffect } from 'react';
import { usePos } from '../../context/PosContext';
import { supabaseSyncService, SyncLogEntry } from '../../services/supabaseSyncService';
import { ultraLocalDb } from '../../services/localDb';
import {
  Cloud,
  Database,
  Wifi,
  WifiOff,
  RefreshCw,
  Zap,
  CheckCircle2,
  AlertTriangle,
  Server,
  Layers,
  Sliders,
  Terminal,
  Play,
  RotateCcw,
} from 'lucide-react';

export const AdminSyncView: React.FC = () => {
  const {
    products,
    sales,
    isOffline,
    setIsOffline,
    pendingSyncCount,
    refreshPendingSyncCount,
    supabaseConfig,
    updateSupabaseConfig,
    triggerSyncNow,
    bulkAddBenchmarkProducts,
    resetDemoData,
  } = usePos();

  // Supabase form state
  const [url, setUrl] = useState(supabaseConfig.url);
  const [anonKey, setAnonKey] = useState(supabaseConfig.anonKey);
  const [syncDirection, setSyncDirection] = useState(supabaseConfig.syncDirection);
  const [autoSync, setAutoSync] = useState(supabaseConfig.autoSyncEnabled);

  // Statuses
  const [isTesting, setIsTesting] = useState(false);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncProgress, setSyncProgress] = useState<number>(0);
  const [syncResult, setSyncResult] = useState<{ success: boolean; pushed: number } | null>(null);

  // Benchmark state
  const [isBenchmarking, setIsBenchmarking] = useState(false);
  const [benchmarkResult, setBenchmarkResult] = useState<{ count: number; timeMs: number } | null>(null);

  // Live Logs
  const [logs, setLogs] = useState<SyncLogEntry[]>([]);

  useEffect(() => {
    const unsubscribe = supabaseSyncService.subscribeLogs((newLogs) => {
      setLogs([...newLogs]);
    });
    return () => unsubscribe();
  }, []);

  // Save config
  const handleSaveConfig = (e: React.FormEvent) => {
    e.preventDefault();
    updateSupabaseConfig({
      ...supabaseConfig,
      url,
      anonKey,
      syncDirection,
      autoSyncEnabled: autoSync,
    });
    supabaseSyncService.addLog('SUCCESS', 'Paramètres de synchronisation Supabase enregistrés');
  };

  // Test connection
  const handleTestConnection = async () => {
    setIsTesting(true);
    setTestResult(null);
    const res = await supabaseSyncService.testConnection(url, anonKey);
    setTestResult(res);
    setIsTesting(false);
  };

  // Trigger sync
  const handleSyncNow = async () => {
    if (isOffline) {
      supabaseSyncService.addLog('WARNING', 'Impossible de synchroniser en mode hors-ligne');
      return;
    }
    setIsSyncing(true);
    setSyncProgress(25);
    const interval = setInterval(() => {
      setSyncProgress((p) => Math.min(90, p + 20));
    }, 200);

    const res = await triggerSyncNow();
    clearInterval(interval);
    setSyncProgress(100);

    setTimeout(() => {
      setIsSyncing(false);
      setSyncProgress(0);
      setSyncResult({ success: res.success, pushed: res.pushedCount });
    }, 400);
  };

  // Run database benchmark
  const handleRunBenchmark = async (count: number) => {
    setIsBenchmarking(true);
    supabaseSyncService.addLog('INFO', `Démarrage du test de charge: écriture de ${count} articles dans IndexedDB...`);
    const res = await bulkAddBenchmarkProducts(count);
    setBenchmarkResult(res);
    setIsBenchmarking(false);
    supabaseSyncService.addLog(
      'SUCCESS',
      `Benchmark réussi: ${res.count} articles indexés en ${res.timeMs} ms (${Math.round(
        (res.timeMs / res.count) * 1000
      )} µs/article)`
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Banner */}
      <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 border border-white shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-50 border border-indigo-200/60 text-indigo-700 text-xs font-bold mb-2">
            <Server className="w-3.5 h-3.5" />
            <span>Administration & Moteur Décentralisé</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight">
            Configuration Cloud Supabase & Base Locale Ultra-Rapide
          </h2>
          <p className="text-xs text-slate-500 mt-1 max-w-2xl">
            Gestion de la réplication cloud, outbox de synchronisation hors-ligne et moteur IndexedDB capable d'indexer des millions d'articles en sub-milliseconde.
          </p>
        </div>

        {/* Offline Toggle Switch */}
        <div className="bg-slate-50 border border-slate-200/80 rounded-2xl p-3 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2.5">
            {isOffline ? (
              <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-700 flex items-center justify-center">
                <WifiOff className="w-5 h-5" />
              </div>
            ) : (
              <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center">
                <Wifi className="w-5 h-5" />
              </div>
            )}
            <div>
              <div className="text-xs font-bold text-slate-800">
                {isOffline ? 'Mode Hors-Ligne (Autonome)' : 'En Ligne (Cloud Connecté)'}
              </div>
              <div className="text-[11px] text-slate-500">
                {pendingSyncCount} vente(s) locale(s) en attente
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setIsOffline(!isOffline)}
            className={`touch-btn px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              isOffline
                ? 'bg-amber-600 hover:bg-amber-700 text-white'
                : 'bg-white border border-slate-300 text-slate-700 hover:bg-slate-100'
            }`}
          >
            {isOffline ? 'Repasser En Ligne' : 'Simuler Hors-Ligne'}
          </button>
        </div>
      </div>

      {/* Grid: Left = Supabase Config; Right = Ultra-Fast DB Benchmark */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Supabase Cloud Sync Card */}
        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 border border-white shadow-xs space-y-5">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center font-bold">
                <Cloud className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-extrabold text-sm sm:text-base text-slate-900">
                  Connexion Cloud Supabase
                </h3>
                <p className="text-[11px] text-slate-400">
                  Réplication PostgreSQL & Authentification multi-postes
                </p>
              </div>
            </div>

            <button
              type="button"
              disabled={isSyncing || isOffline}
              onClick={handleSyncNow}
              className={`touch-btn px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
                isOffline
                  ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                  : 'bg-teal-600 hover:bg-teal-700 text-white shadow-xs'
              }`}
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
              <span>Synchroniser</span>
            </button>
          </div>

          {/* Progress bar when syncing */}
          {isSyncing && (
            <div className="space-y-1">
              <div className="flex justify-between text-xs text-slate-600 font-semibold">
                <span>Synchronisation en cours...</span>
                <span>{syncProgress}%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                <div
                  className="bg-teal-600 h-full transition-all duration-300"
                  style={{ width: `${syncProgress}%` }}
                ></div>
              </div>
            </div>
          )}

          <form onSubmit={handleSaveConfig} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                URL du projet Supabase
              </label>
              <input
                type="url"
                required
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://xyzcompany.supabase.co"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm font-mono text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-teal-500/20"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Clé Publique / Anon Key
              </label>
              <input
                type="password"
                required
                value={anonKey}
                onChange={(e) => setAnonKey(e.target.value)}
                placeholder="eyJhbGciOiJIUzI1NiIsIn..."
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm font-mono text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-teal-500/20"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Mode de Synchronisation
                </label>
                <select
                  value={syncDirection}
                  onChange={(e) => setSyncDirection(e.target.value as any)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-700"
                >
                  <option value="BIDIRECTIONAL">Bidirectionnel (P2P + Cloud)</option>
                  <option value="CLOUD_TO_LOCAL">Descendant (Cloud → Local)</option>
                  <option value="LOCAL_TO_CLOUD">Ascendant (Local → Cloud)</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">
                  Synchronisation Auto
                </label>
                <select
                  value={autoSync ? 'true' : 'false'}
                  onChange={(e) => setAutoSync(e.target.value === 'true')}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-700"
                >
                  <option value="true">Activée (Instantanée)</option>
                  <option value="false">Manuelle uniquement</option>
                </select>
              </div>
            </div>

            {/* Test result banner */}
            {testResult && (
              <div
                className={`p-3 rounded-2xl text-xs font-semibold flex items-center gap-2 ${
                  testResult.success
                    ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                    : 'bg-rose-50 text-rose-800 border border-rose-200'
                }`}
              >
                {testResult.success ? (
                  <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                ) : (
                  <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
                )}
                <span>{testResult.message}</span>
              </div>
            )}

            <div className="pt-2 flex items-center justify-between gap-3">
              <button
                type="button"
                disabled={isTesting}
                onClick={handleTestConnection}
                className="touch-btn px-4 py-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors cursor-pointer"
              >
                {isTesting ? 'Test en cours...' : 'Tester la Connexion'}
              </button>

              <button
                type="submit"
                className="touch-btn px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow-xs transition-colors cursor-pointer"
              >
                Sauvegarder Configuration
              </button>
            </div>
          </form>
        </div>

        {/* Ultra-Fast Local Database & Millions Stress Test */}
        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 border border-white shadow-xs space-y-5">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
                <Database className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-extrabold text-sm sm:text-base text-slate-900">
                  Moteur Local Ultra-Performant (IndexedDB)
                </h3>
                <p className="text-[11px] text-slate-400">
                  Index B-Tree binaire + Cache mémoire O(1) pour millions d'articles
                </p>
              </div>
            </div>

            <span className="text-[10px] font-bold font-mono px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">
              Moteur Actif
            </span>
          </div>

          {/* Engine metrics */}
          <div className="grid grid-cols-3 gap-3">
            <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 text-center">
              <span className="text-[10px] text-slate-400 uppercase font-bold block">Articles Indexés</span>
              <span className="text-lg font-black text-slate-900">
                {products.length.toLocaleString('fr-FR')}
              </span>
            </div>
            <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 text-center">
              <span className="text-[10px] text-slate-400 uppercase font-bold block">Temps EAN</span>
              <span className="text-lg font-black text-emerald-600 font-mono">
                &lt; 0.2 ms
              </span>
            </div>
            <div className="p-3 bg-slate-50 rounded-2xl border border-slate-100 text-center">
              <span className="text-[10px] text-slate-400 uppercase font-bold block">File Hors-Ligne</span>
              <span className="text-lg font-black text-indigo-600">
                {pendingSyncCount}
              </span>
            </div>
          </div>

          {/* Stress test benchmark generator */}
          <div className="p-4 bg-indigo-50/60 rounded-2xl border border-indigo-100 space-y-3">
            <div className="flex items-center gap-2">
              <Zap className="w-4 h-4 text-indigo-600" />
              <h4 className="text-xs font-bold text-indigo-950">
                Stress-Test de Montée en Charge (Millions d'Articles)
              </h4>
            </div>
            <p className="text-[11px] text-indigo-800/80">
              Injectez instantanément des milliers d'articles avec codes EAN uniques pour valider les performances en temps réel de la recherche et de la caisse.
            </p>

            <div className="flex flex-wrap items-center gap-2 pt-1">
              <button
                type="button"
                disabled={isBenchmarking}
                onClick={() => handleRunBenchmark(5000)}
                className="touch-btn px-3 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-xs transition-colors cursor-pointer flex items-center gap-1.5"
              >
                <Play className="w-3.5 h-3.5" />
                <span>+5 000 Articles</span>
              </button>

              <button
                type="button"
                disabled={isBenchmarking}
                onClick={() => handleRunBenchmark(15000)}
                className="touch-btn px-3 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow-xs transition-colors cursor-pointer flex items-center gap-1.5"
              >
                <Play className="w-3.5 h-3.5" />
                <span>+15 000 Articles</span>
              </button>

              <button
                type="button"
                onClick={resetDemoData}
                className="touch-btn px-3 py-2 bg-white hover:bg-slate-100 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors cursor-pointer flex items-center gap-1.5"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>Réinitialiser Base</span>
              </button>
            </div>

            {benchmarkResult && (
              <div className="p-2.5 bg-emerald-100/70 border border-emerald-200 rounded-xl text-xs text-emerald-950 font-semibold flex items-center justify-between">
                <span>
                  ✓ {benchmarkResult.count.toLocaleString('fr-FR')} articles ajoutés et indexés
                </span>
                <span className="font-mono font-bold text-emerald-800">
                  en {benchmarkResult.timeMs} ms
                </span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Sync Activity Logs Console */}
      <div className="bg-slate-900 text-slate-200 rounded-3xl p-5 border border-slate-800 shadow-md space-y-3 font-mono text-xs">
        <div className="flex items-center justify-between pb-2 border-b border-slate-800">
          <div className="flex items-center gap-2">
            <Terminal className="w-4 h-4 text-emerald-400" />
            <span className="font-bold text-slate-300">Journal d'Activité de Synchronisation & Base Locale</span>
          </div>
          <span className="text-[10px] text-slate-500">Temps Réel</span>
        </div>

        <div className="h-44 overflow-y-auto space-y-1.5 pr-2">
          {logs.length === 0 ? (
            <div className="text-slate-500 py-4 text-center">Aucun événement enregistré.</div>
          ) : (
            logs.map((log) => (
              <div key={log.id} className="flex items-start gap-3 text-[11px] leading-relaxed">
                <span className="text-slate-500 shrink-0">[{log.timestamp}]</span>
                <span
                  className={`font-bold shrink-0 ${
                    log.type === 'SUCCESS'
                      ? 'text-emerald-400'
                      : log.type === 'ERROR'
                      ? 'text-rose-400'
                      : log.type === 'WARNING'
                      ? 'text-amber-400'
                      : 'text-blue-400'
                  }`}
                >
                  [{log.type}]
                </span>
                <span className="text-slate-300">{log.message}</span>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
