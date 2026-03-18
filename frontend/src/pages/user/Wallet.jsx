import React, { useState } from 'react';
import { FileText, ShieldCheck, Clock, DownloadCloud } from 'lucide-react';
import api from '../../api';

const CategoryIcon = {
  Education: <BookOpen className="w-5 h-5" />,
  Medical: <Activity className="w-5 h-5" />,
  Government: <Landmark className="w-5 h-5" />,
  Other: <FileText className="w-5 h-5" />
};

import { BookOpen, Activity, Landmark, Plus } from 'lucide-react';

const DocumentCard = ({ doc }) => {
  const isExpired = doc.expiryDate && new Date(doc.expiryDate) < new Date();
  
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-purple-500/50 transition-all group">
      <div className="flex justify-between items-start mb-4">
        <div className="p-3 bg-slate-800 rounded-lg text-purple-400 group-hover:scale-110 transition-transform">
          {CategoryIcon[doc.category] || CategoryIcon['Other']}
        </div>
        <div className={`px-2.5 py-1 text-xs font-medium rounded-full flex items-center ${
          doc.isVerified ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
        }`}>
          {doc.isVerified ? <ShieldCheck className="w-3 h-3 mr-1" /> : <Clock className="w-3 h-3 mr-1" />}
          {doc.isVerified ? 'Verified' : 'Pending'}
        </div>
      </div>
      
      <h3 className="font-semibold text-slate-200 truncate" title={doc.title}>{doc.title}</h3>
      <p className="text-sm text-slate-500 mt-1">{doc.category}</p>
      
      {doc.issuerId && (
        <p className="text-xs text-slate-400 mt-4 flex items-center">
          <span className="text-slate-500 mr-1">Issued by:</span> 
          {doc.issuerId.orgName}
        </p>
      )}
      
      {doc.expiryDate && (
        <p className={`text-xs mt-2 flex items-center ${isExpired ? 'text-red-400' : 'text-slate-400'}`}>
          <Clock className="w-3 h-3 mr-1" />
          {isExpired ? 'Expired' : 'Valid till'}: {new Date(doc.expiryDate).toLocaleDateString()}
        </p>
      )}
    </div>
  );
};

const WalletDashboard = ({ documents, refreshDocs }) => {
  const [uploading, setUploading] = useState(false);

  const handleMockUpload = async () => {
    // Simulating an upload or fetching from Govt Digilocker API
    setUploading(true);
    try {
      await api.post('/documents', {
        title: `Aadhaar Card - Mocked ${Math.floor(Math.random() * 1000)}`,
        category: 'Government',
        fileUrl: 'https://firebasestorage.googleapis.com/v0/b/mock.appspot.com/o/mock.pdf',
        metadata: { 'ID Number': '1234-5678-9012', 'DOB': '1990-01-01' }
      });
      refreshDocs();
    } catch (error) {
      console.error('Upload failed', error);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">My Document Wallet</h1>
          <p className="text-slate-400 mt-2">Manage and view your securely stored documents.</p>
        </div>
        <button 
          onClick={handleMockUpload}
          disabled={uploading}
          className="flex items-center px-4 py-2.5 bg-purple-600 hover:bg-purple-500 text-white rounded-lg font-medium transition-colors shadow-lg shadow-purple-900/40 disabled:opacity-50"
        >
          {uploading ? <Clock className="w-5 h-5 mr-2 animate-spin" /> : <Plus className="w-5 h-5 mr-2" />}
          Add Document (Mock)
        </button>
      </div>

      {documents.length === 0 ? (
        <div className="text-center py-20 bg-slate-900/50 border border-slate-800 rounded-2xl border-dashed">
          <DownloadCloud className="w-16 h-16 mx-auto text-slate-600 mb-4" />
          <h3 className="text-xl font-semibold text-slate-300">Your wallet is empty</h3>
          <p className="text-slate-500 mt-2 max-w-md mx-auto">Upload your first document or request an educational/medical institution to issue one to your TrustVault.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {documents.map((doc) => (
            <DocumentCard key={doc._id} doc={doc} />
          ))}
        </div>
      )}
    </div>
  );
};

export default WalletDashboard;
