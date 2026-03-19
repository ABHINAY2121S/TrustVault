import React, { useState, useCallback } from 'react';
import { Folder, Plus, Trash2, FileText, X, ChevronRight, FolderOpen, ShieldCheck, Clock, AlertTriangle } from 'lucide-react';
import api from '../../api';

const FOLDER_COLORS = [
  '#7c3aed', '#2563eb', '#059669', '#d97706', '#dc2626', '#db2777', '#0891b2'
];

const VerificationBadge = ({ status }) => {
  const config = {
    verified: { label: 'Verified', cls: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30', icon: <ShieldCheck className="w-3 h-3" /> },
    partially_verified: { label: 'Partial', cls: 'bg-amber-500/10 text-amber-400 border border-amber-500/30', icon: <Clock className="w-3 h-3" /> },
    unverified: { label: 'Unverified', cls: 'bg-slate-700/50 text-slate-400 border border-slate-600/30', icon: <AlertTriangle className="w-3 h-3" /> },
  };
  const c = config[status] || config.unverified;
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${c.cls}`}>
      {c.icon}{c.label}
    </span>
  );
};

const Folders = ({ documents, refreshDocs }) => {
  const [folders, setFolders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadedFolders, setLoadedFolders] = useState(false);
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [folderDocs, setFolderDocs] = useState([]);
  const [showCreate, setShowCreate] = useState(false);
  const [showAddDoc, setShowAddDoc] = useState(false);
  const [newName, setNewName] = useState('');
  const [newColor, setNewColor] = useState(FOLDER_COLORS[0]);
  const [creating, setCreating] = useState(false);

  const fetchFolders = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await api.get('/folders');
      setFolders(data);
      setLoadedFolders(true);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  React.useEffect(() => { fetchFolders(); }, [fetchFolders]);

  const openFolder = async (folder) => {
    setSelectedFolder(folder);
    try {
      const { data } = await api.get(`/folders/${folder._id}/documents`);
      setFolderDocs(data.documents);
    } catch (err) {
      console.error(err);
    }
  };

  const createFolder = async (e) => {
    e.preventDefault();
    if (!newName.trim()) return;
    setCreating(true);
    try {
      await api.post('/folders', { name: newName, color: newColor });
      setNewName('');
      setNewColor(FOLDER_COLORS[0]);
      setShowCreate(false);
      fetchFolders();
    } catch (err) {
      console.error(err);
    } finally {
      setCreating(false);
    }
  };

  const deleteFolder = async (id) => {
    if (!window.confirm('Delete this folder? Documents inside will be kept but unlinked.')) return;
    try {
      await api.delete(`/folders/${id}`);
      if (selectedFolder?._id === id) setSelectedFolder(null);
      fetchFolders();
    } catch (err) {
      console.error(err);
    }
  };

  const addDocToFolder = async (docId) => {
    if (!selectedFolder) return;
    try {
      await api.put(`/folders/${selectedFolder._id}/add/${docId}`);
      openFolder(selectedFolder);
      setShowAddDoc(false);
    } catch (err) {
      console.error(err);
    }
  };

  const removeDocFromFolder = async (docId) => {
    try {
      await api.put(`/folders/remove/${docId}`);
      openFolder(selectedFolder);
    } catch (err) {
      console.error(err);
    }
  };

  // Docs NOT already in this folder
  const unassignedDocs = documents.filter(d => !d.folderId || d.folderId !== selectedFolder?._id);

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-100 flex items-center gap-3">
            <Folder className="w-8 h-8 text-purple-500" />
            My Folders
          </h1>
          <p className="text-slate-400 mt-1">Organize your documents into folders for easy access.</p>
        </div>
        <button onClick={() => setShowCreate(true)} className="btn-primary px-5 py-2.5 flex items-center gap-2">
          <Plus className="w-4 h-4" /> New Folder
        </button>
      </div>

      {/* Create folder modal */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <h2 className="text-xl font-semibold text-slate-100 mb-5">Create New Folder</h2>
            <form onSubmit={createFolder} className="space-y-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Folder Name</label>
                <input
                  autoFocus
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. Education Documents"
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-slate-200 focus:outline-none focus:border-purple-500"
                />
              </div>
              <div>
                <label className="block text-sm text-slate-400 mb-2">Color</label>
                <div className="flex gap-2">
                  {FOLDER_COLORS.map(c => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => setNewColor(c)}
                      className={`w-8 h-8 rounded-full transition-all ${newColor === c ? 'ring-2 ring-white ring-offset-2 ring-offset-slate-900 scale-110' : ''}`}
                      style={{ backgroundColor: c }}
                    />
                  ))}
                </div>
              </div>
              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setShowCreate(false)} className="flex-1 px-4 py-2.5 border border-slate-700 rounded-xl text-slate-400 hover:text-slate-200 hover:border-slate-500 transition-colors">
                  Cancel
                </button>
                <button type="submit" disabled={creating || !newName.trim()} className="flex-1 btn-primary py-2.5 disabled:opacity-50">
                  {creating ? 'Creating...' : 'Create Folder'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add doc to folder modal */}
      {showAddDoc && selectedFolder && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-md shadow-2xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold text-slate-100">Add Document</h2>
              <button onClick={() => setShowAddDoc(false)} className="text-slate-400 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1 space-y-2">
              {unassignedDocs.length === 0 ? (
                <p className="text-slate-500 text-sm text-center py-6">All documents are already in this folder or another.</p>
              ) : (
                unassignedDocs.map(doc => (
                  <button
                    key={doc._id}
                    onClick={() => addDocToFolder(doc._id)}
                    className="w-full flex items-center gap-3 p-3 rounded-xl bg-slate-800/50 hover:bg-slate-700/50 border border-slate-700/50 hover:border-purple-500/30 transition-all text-left group"
                  >
                    <FileText className="w-5 h-5 text-slate-400 group-hover:text-purple-400" />
                    <div className="flex-1 min-w-0">
                      <p className="text-slate-200 text-sm font-medium truncate">{doc.title}</p>
                      <p className="text-slate-500 text-xs">{doc.category}</p>
                    </div>
                    <VerificationBadge status={doc.verificationStatus} />
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Folders List */}
        <div className="space-y-3">
          {loading && !loadedFolders ? (
            <div className="text-slate-500 text-sm text-center py-8">Loading folders...</div>
          ) : folders.length === 0 ? (
            <div className="text-center py-12 text-slate-500">
              <Folder className="w-12 h-12 mx-auto mb-3 opacity-30" />
              <p className="text-sm">No folders yet. Create one to organize your documents.</p>
            </div>
          ) : (
            folders.map(folder => (
              <button
                key={folder._id}
                onClick={() => openFolder(folder)}
                className={`w-full flex items-center gap-3 p-4 rounded-xl border transition-all text-left group ${
                  selectedFolder?._id === folder._id
                    ? 'border-purple-500/40 bg-purple-600/10'
                    : 'border-slate-800 bg-slate-900/50 hover:border-slate-700'
                }`}
              >
                <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: folder.color + '33' }}>
                  <FolderOpen className="w-5 h-5" style={{ color: folder.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-slate-200 font-medium truncate">{folder.name}</p>
                  <p className="text-slate-500 text-xs">{folder.documentCount} document{folder.documentCount !== 1 ? 's' : ''}</p>
                </div>
                <div className="flex items-center gap-1">
                  <button
                    onClick={(e) => { e.stopPropagation(); deleteFolder(folder._id); }}
                    className="p-1.5 rounded-lg text-slate-600 hover:text-red-400 hover:bg-red-500/10 opacity-0 group-hover:opacity-100 transition-all"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                  <ChevronRight className={`w-4 h-4 text-slate-500 transition-transform ${selectedFolder?._id === folder._id ? 'rotate-90 text-purple-400' : ''}`} />
                </div>
              </button>
            ))
          )}
        </div>

        {/* Folder Contents */}
        <div className="lg:col-span-2">
          {!selectedFolder ? (
            <div className="h-full flex items-center justify-center min-h-[300px]">
              <div className="text-center text-slate-600">
                <FolderOpen className="w-16 h-16 mx-auto mb-3 opacity-40" />
                <p>Select a folder to view documents</p>
              </div>
            </div>
          ) : (
            <div className="bg-slate-900/50 border border-slate-800 rounded-2xl p-5">
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ backgroundColor: selectedFolder.color + '33' }}>
                    <FolderOpen className="w-4 h-4" style={{ color: selectedFolder.color }} />
                  </div>
                  <h2 className="text-lg font-semibold text-slate-100">{selectedFolder.name}</h2>
                </div>
                <button
                  onClick={() => setShowAddDoc(true)}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-purple-500/30 text-purple-400 hover:bg-purple-500/10 text-sm transition-colors"
                >
                  <Plus className="w-3.5 h-3.5" /> Add Document
                </button>
              </div>
              {folderDocs.length === 0 ? (
                <div className="text-center py-10 text-slate-500">
                  <FileText className="w-10 h-10 mx-auto mb-2 opacity-30" />
                  <p className="text-sm">This folder is empty. Add documents to organize them here.</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {folderDocs.map(doc => (
                    <div key={doc._id} className="flex items-center gap-3 p-3 rounded-xl bg-slate-800/50 border border-slate-700/40 group">
                      <FileText className="w-5 h-5 text-slate-400 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <p className="text-slate-200 text-sm font-medium truncate">{doc.title}</p>
                        <p className="text-slate-500 text-xs">{doc.category} · Added {new Date(doc.createdAt).toLocaleDateString()}</p>
                      </div>
                      <VerificationBadge status={doc.verificationStatus} />
                      <button
                        onClick={() => removeDocFromFolder(doc._id)}
                        className="p-1.5 rounded-lg text-slate-600 hover:text-red-400 hover:bg-red-500/10 opacity-0 group-hover:opacity-100 transition-all ml-1"
                        title="Remove from folder"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Folders;
